import '../../../core/network/api_client.dart';
import '../../community/data/community_api_mapper.dart';
import '../../community/data/people_directory.dart';
import 'moderation_repository.dart';

/// [ModerationRepository] (blocking) backed by the FCU API. The set of
/// blocked ids is cached so [isBlocked] can stay synchronous; it is filled by
/// [getBlockedUserIds] (the app asks for it before showing any list).
class RemoteModerationRepository implements ModerationRepository {
  RemoteModerationRepository(
    this._api,
    this._directory, {
    String? Function()? currentUserId,
  }) : _currentUserId = currentUserId;

  final ApiClient _api;
  final PeopleDirectory _directory;
  final String? Function()? _currentUserId;
  final Set<String> _blocked = {};

  @override
  Future<void> blockUser(String userId) async {
    if (userId == _currentUserId?.call()) {
      throw ArgumentError.value(userId, 'userId', 'cannot block yourself');
    }
    await _api.put('/users/$userId/block');
    _blocked.add(userId);
  }

  @override
  Future<void> unblockUser(String userId) async {
    await _api.delete('/users/$userId/block');
    _blocked.remove(userId);
  }

  @override
  Future<Set<String>> getBlockedUserIds() async {
    final items = await _api.getAllItems('/me/blocks');
    _blocked
      ..clear()
      ..addAll([
        for (final j in items)
          memberFromApi(j, remember: _directory).person.id,
      ]);
    return Set.unmodifiable(_blocked);
  }

  @override
  bool isBlocked(String userId) => _blocked.contains(userId);
}
