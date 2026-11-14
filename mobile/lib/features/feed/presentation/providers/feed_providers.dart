import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../messaging/presentation/providers/moderation_providers.dart';
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

  /// Swaps in a newer copy of a post (e.g. after a like or comment on the
  /// post screen) without reloading the feed.
  void replacePost(Post post) => _replace(post.id, (_) => post);

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
