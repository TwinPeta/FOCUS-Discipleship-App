import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../community/domain/community.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../domain/post.dart';

class FeedPostsController extends FamilyAsyncNotifier<List<Post>, String> {
  Future<PostScope> _scopeFor(String communityId) async {
    final community = await ref.read(communityByIdProvider(communityId).future);
    return community.type == CommunityType.general
        ? PostScope.general
        : PostScope.specific;
  }

  @override
  Future<List<Post>> build(String communityId) async {
    final scope = await _scopeFor(communityId);
    return ref.watch(postRepositoryProvider).getPosts(communityId, scope);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final scope = await _scopeFor(arg);
    state = AsyncValue.data(
      await ref.read(postRepositoryProvider).getPosts(arg, scope),
    );
  }

  /// Toggles the like locally first (optimistic), then persists through the
  /// repository.
  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final toggled = current[index].copyWith(
      likedByMe: !current[index].likedByMe,
      likeCount: current[index].likedByMe
          ? current[index].likeCount - 1
          : current[index].likeCount + 1,
    );
    final optimistic = [...current];
    optimistic[index] = toggled;
    state = AsyncValue.data(optimistic);

    await ref.read(postRepositoryProvider).toggleLike(toggled);
  }

  /// Inserts [post] at the top immediately (optimistic), then persists it.
  Future<void> createPost(Post post) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([post, ...current]);
    await ref.read(postRepositoryProvider).createPost(post);
  }
}

final feedPostsProvider =
    AsyncNotifierProvider.family<FeedPostsController, List<Post>, String>(
      FeedPostsController.new,
    );
