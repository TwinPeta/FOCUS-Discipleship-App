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

class FakeModerationRepository implements ModerationRepository {
  FakeModerationRepository({
    this.latency = const Duration(milliseconds: 400),
    this.currentUserId,
  });

  final Duration latency;

  /// Read lazily: the signed-in user, who cannot block themselves.
  final String? Function()? currentUserId;

  final Set<String> _blocked = {};

  @override
  Future<void> blockUser(String userId) async {
    await Future.delayed(latency);
    if (userId == currentUserId?.call()) {
      throw ArgumentError.value(userId, 'userId', 'cannot block yourself');
    }
    _blocked.add(userId);
  }

  @override
  Future<void> unblockUser(String userId) async {
    await Future.delayed(latency);
    _blocked.remove(userId);
  }

  @override
  Future<Set<String>> getBlockedUserIds() async {
    await Future.delayed(latency);
    return Set.unmodifiable(_blocked);
  }

  @override
  bool isBlocked(String userId) => _blocked.contains(userId);
}
