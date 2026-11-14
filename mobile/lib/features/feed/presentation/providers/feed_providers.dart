import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../community/domain/person.dart';
import '../../../community/domain/user_role.dart';
import '../../../community/presentation/providers/membership_provider.dart';
import '../../../messaging/presentation/providers/moderation_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/comment.dart';
import '../../domain/post.dart';

/// One feed (General or a specific community), paged, newest first.
/// Likes and new posts are optimistic and roll back on failure.
class FeedPostsController extends FamilyAsyncNotifier<List<Post>, FeedKey> {
  String? _nextCursor;
  bool _loadingMore = false;

  bool get hasMore => _nextCursor != null;

  Future<List<Post>> _firstPage() async {
    final page = await ref
        .read(postRepositoryProvider)
        .getPosts(arg.communityId, arg.scope);
    _nextCursor = page.nextCursor;
    return page.items;
  }

  List<Post> _visible(List<Post> posts, Set<String> blocked) =>
      posts.where((p) => !blocked.contains(p.author.id)).toList();

  @override
  Future<List<Post>> build(FeedKey arg) async {
    ref.watch(postRepositoryProvider);
    final blocked = await ref.watch(blockedUserIdsProvider.future);
    return _visible(await _firstPage(), blocked);
  }

  /// Pull-to-refresh: keeps the current list on screen while loading and
  /// rethrows on failure (the list stays as it was).
  Future<void> refresh() async {
    final blocked = await ref.read(blockedUserIdsProvider.future);
    state = AsyncValue.data(_visible(await _firstPage(), blocked));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || _nextCursor == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(postRepositoryProvider)
          .getPosts(arg.communityId, arg.scope, cursor: _nextCursor);
      _nextCursor = page.nextCursor;
      final blocked = await ref.read(blockedUserIdsProvider.future);
      final seen = {for (final p in current) p.id};
      state = AsyncValue.data([
        ...current,
        ..._visible(page.items, blocked).where((p) => !seen.contains(p.id)),
      ]);
    } finally {
      _loadingMore = false;
    }
  }

  void _replace(String postId, Post Function(Post) update) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final p in current) p.id == postId ? update(p) : p,
    ]);
  }

  /// Updates an already-loaded post in place (e.g. after liking on detail).
  void syncPost(Post updated) {
    _replace(updated.id, (_) => updated);
  }

  /// Flips the like locally, persists the *intended* value, and restores
  /// the previous post if the repository fails.
  Future<void> toggleLike(String postId) async {
    final before = state.valueOrNull?.where((p) => p.id == postId).firstOrNull;
    if (before == null) return;
    final liked = !before.likedByMe;
    _replace(
      postId,
      (p) => p.copyWith(
        likedByMe: liked,
        likeCount: p.likeCount + (liked ? 1 : -1),
      ),
    );
    try {
      final saved = await ref
          .read(postRepositoryProvider)
          .setLiked(postId, liked: liked);
      _replace(postId, (_) => saved);
      ref.invalidate(postDetailProvider(postId));
    } catch (_) {
      _replace(postId, (_) => before);
      rethrow;
    }
  }

  /// Inserts [post] at the top once (deduped by id), then persists it.
  /// Removes it again and rethrows if the repository fails.
  Future<void> createPost(Post post) async {
    final current = state.valueOrNull ?? const <Post>[];
    state = AsyncValue.data([post, ...current.where((p) => p.id != post.id)]);
    try {
      await ref.read(postRepositoryProvider).createPost(post);
    } catch (_) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const <Post>[])
            .where((p) => p.id != post.id)
            .toList(),
      );
      rethrow;
    }
  }
}

final feedPostsProvider =
    AsyncNotifierProvider.family<FeedPostsController, List<Post>, FeedKey>(
      FeedPostsController.new,
    );

/// Loads a single post for Screen 39 (`/post/:id`), returning null when missing
/// or authored by a blocked user. Likes update optimistically and roll back on
/// failure.
class PostDetailController extends FamilyAsyncNotifier<Post?, String> {
  @override
  Future<Post?> build(String arg) async {
    final repo = ref.watch(postRepositoryProvider);
    final blocked = await ref.watch(blockedUserIdsProvider.future);
    final post = await repo.getPostById(arg);
    if (post == null || blocked.contains(post.author.id)) return null;
    return post;
  }

  Future<void> toggleLike() async {
    final before = state.valueOrNull;
    if (before == null) return;
    final liked = !before.likedByMe;
    state = AsyncValue.data(
      before.copyWith(
        likedByMe: liked,
        likeCount: before.likeCount + (liked ? 1 : -1),
      ),
    );
    try {
      final saved = await ref
          .read(postRepositoryProvider)
          .setLiked(before.id, liked: liked);
      state = AsyncValue.data(saved);
      ref
          .read(
            feedPostsProvider((
              communityId: saved.communityId,
              scope: saved.scope,
            )).notifier,
          )
          .syncPost(saved);
    } catch (_) {
      state = AsyncValue.data(before);
      rethrow;
    }
  }
}

final postDetailProvider =
    AsyncNotifierProvider.family<PostDetailController, Post?, String>(
      PostDetailController.new,
    );

/// Comments on a post, chronological (oldest first), with blocked users hidden.
/// Adding a comment is optimistic and rolls back on failure.
class PostCommentsController extends FamilyAsyncNotifier<List<Comment>, String> {
  @override
  Future<List<Comment>> build(String arg) async {
    final repo = ref.watch(postRepositoryProvider);
    final blocked = await ref.watch(blockedUserIdsProvider.future);
    final comments = await repo.getComments(arg);
    return comments.where((c) => !blocked.contains(c.author.id)).toList();
  }

  Future<void> addComment(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final profile = ref.read(currentProfileProvider);
    final role = switch (ref.read(currentRoleProvider)) {
      UserRole.superMentor => PersonRole.superMentor,
      UserRole.mentor => PersonRole.mentor,
      UserRole.student => PersonRole.member,
    };
    final author = Person(
      id: profile?.id ?? 'me',
      name: profile?.fullName ?? 'You',
      role: role,
    );
    final optimistic = Comment(
      id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
      postId: arg,
      author: author,
      body: trimmed,
      createdAt: DateTime.now(),
    );

    final current = state.valueOrNull ?? const <Comment>[];
    state = AsyncValue.data([...current, optimistic]);
    try {
      final saved = await ref
          .read(postRepositoryProvider)
          .addComment(arg, optimistic);
      final latest = state.valueOrNull ?? const <Comment>[];
      state = AsyncValue.data([
        for (final c in latest) c.id == optimistic.id ? saved : c,
      ]);
    } catch (_) {
      final latest = state.valueOrNull ?? const <Comment>[];
      state = AsyncValue.data(
        latest.where((c) => c.id != optimistic.id).toList(),
      );
      rethrow;
    }
  }
}

final postCommentsProvider =
    AsyncNotifierProvider.family<PostCommentsController, List<Comment>, String>(
      PostCommentsController.new,
    );
