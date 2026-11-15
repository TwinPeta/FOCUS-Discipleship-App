import 'package:focus_1/features/messaging/data/moderation_repository.dart';

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
