abstract class ModerationRepository {
  Future<void> blockUser(String userId);
  Future<Set<String>> getBlockedUserIds();
}

class FakeModerationRepository implements ModerationRepository {
  static const _latency = Duration(milliseconds: 400);

  final Set<String> _blocked = {};

  @override
  Future<void> blockUser(String userId) async {
    await Future.delayed(_latency);
    _blocked.add(userId);
  }

  @override
  Future<Set<String>> getBlockedUserIds() async {
    await Future.delayed(_latency);
    return Set.unmodifiable(_blocked);
  }
}
