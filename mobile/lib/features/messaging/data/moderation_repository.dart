/// The current user's blocks. Repositories that return people or what they
/// wrote take [isBlocked] and filter on it, so a block applies everywhere
/// (inbox, feeds, comments, prayer wall, testimonies, member lists).
abstract class ModerationRepository {
  /// Idempotent. Throws [ArgumentError] for the user's own id.
  Future<void> blockUser(String userId);

  /// Idempotent.
  Future<void> unblockUser(String userId);

  Future<Set<String>> getBlockedUserIds();

  /// Synchronous check for other repositories' filters.
  bool isBlocked(String userId);
}
