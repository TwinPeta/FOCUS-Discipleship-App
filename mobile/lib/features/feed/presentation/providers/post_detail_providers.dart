import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../community/domain/person.dart';
import '../../../messaging/presentation/providers/moderation_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/comment.dart';
import '../../domain/post.dart';
import 'feed_providers.dart';

/// Screen 39's post. Null when it does not exist or its author is blocked.
/// Likes are optimistic, and every change is copied into the feed the post
/// belongs to (if that feed is loaded) so both screens agree.
class PostDetailController
    extends AutoDisposeFamilyAsyncNotifier<Post?, String> {
  @override
  Future<Post?> build(String arg) async {
    final blocked = await ref.watch(blockedUserIdsProvider.future);
    final post = await ref.watch(postRepositoryProvider).getPost(arg);
    if (post == null || blocked.contains(post.author.id)) return null;
    return post;
  }

  void _set(Post post) {
    state = AsyncValue.data(post);
    final key = (communityId: post.communityId, scope: post.scope);
    if (ref.exists(feedPostsProvider(key))) {
      ref.read(feedPostsProvider(key).notifier).replacePost(post);
    }
  }

  Future<void> toggleLike() async {
    final before = state.valueOrNull;
    if (before == null) return;
    final liked = !before.likedByMe;
    _set(
      before.copyWith(
        likedByMe: liked,
        likeCount: before.likeCount + (liked ? 1 : -1),
      ),
    );
    try {
      _set(await ref.read(postRepositoryProvider).setLiked(arg, liked: liked));
    } catch (_) {
      _set(before);
      rethrow;
    }
  }

  /// Keeps the comments count in step with [PostCommentsController].
  void adjustCommentCount(int delta) {
    final post = state.valueOrNull;
    if (post == null) return;
    _set(post.copyWith(commentCount: post.commentCount + delta));
  }
}

final postDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PostDetailController, Post?, String>(PostDetailController.new);

/// Comments on one post, oldest first, with blocked authors removed.
/// Adding is optimistic and rolls back on failure.
class PostCommentsController
    extends AutoDisposeFamilyAsyncNotifier<List<Comment>, String> {
  @override
  Future<List<Comment>> build(String arg) async {
    final blocked = await ref.watch(blockedUserIdsProvider.future);
    final comments = await ref.watch(postRepositoryProvider).getComments(arg);
    return comments.where((c) => !blocked.contains(c.author.id)).toList();
  }

  Future<void> add(String text) async {
    final profile = ref.read(currentProfileProvider);
    final trimmed = text.trim();
    if (profile == null || trimmed.isEmpty) return;
    final comment = Comment(
      id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
      postId: arg,
      author: Person(
        id: profile.id,
        name: profile.fullName,
        role: PersonRole.member,
      ),
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final post = ref.read(postDetailProvider(arg).notifier);
    state = AsyncValue.data([...?state.valueOrNull, comment]);
    post.adjustCommentCount(1);
    try {
      final saved = await ref.read(postRepositoryProvider).addComment(comment);
      state = AsyncValue.data([
        for (final c in state.valueOrNull ?? const <Comment>[])
          c.id == comment.id ? saved : c,
      ]);
    } catch (_) {
      state = AsyncValue.data([
        for (final c in state.valueOrNull ?? const <Comment>[])
          if (c.id != comment.id) c,
      ]);
      post.adjustCommentCount(-1);
      rethrow;
    }
  }
}

final postCommentsProvider = AsyncNotifierProvider.autoDispose
    .family<PostCommentsController, List<Comment>, String>(
      PostCommentsController.new,
    );
