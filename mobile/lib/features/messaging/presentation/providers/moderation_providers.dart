import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';

/// Ids the current user has blocked. Every provider that returns
/// user-authored content (threads, posts, prayer requests, members) filters
/// through this, so blocking hides a person everywhere at once.
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(moderationRepositoryProvider).getBlockedUserIds();
});

class ModerationActions {
  ModerationActions(this._ref);
  final Ref _ref;

  /// Blocks [userId] and refreshes every filtered list.
  Future<void> block(String userId) async {
    await _ref.read(moderationRepositoryProvider).blockUser(userId);
    _ref.invalidate(blockedUserIdsProvider);
  }

  /// Undoes [block]; the person's content comes back everywhere.
  Future<void> unblock(String userId) async {
    await _ref.read(moderationRepositoryProvider).unblockUser(userId);
    _ref.invalidate(blockedUserIdsProvider);
  }
}

final moderationActionsProvider = Provider<ModerationActions>(
  ModerationActions.new,
);
