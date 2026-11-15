import '../../../core/network/api_client.dart';
import '../domain/member_profile.dart';
import 'community_api_mapper.dart';
import 'member_repository.dart';
import 'people_directory.dart';

/// [MemberRepository] backed by the FCU API. Profiles of people outside a
/// roster the app has loaded are unknown (the API has no user lookup).
class RemoteMemberRepository implements MemberRepository {
  RemoteMemberRepository(
    this._api,
    this._directory, {
    bool Function(String userId)? isBlocked,
  }) : _isBlocked = isBlocked ?? _nobody;

  final ApiClient _api;
  final PeopleDirectory _directory;
  final bool Function(String userId) _isBlocked;
  static bool _nobody(String _) => false;

  @override
  Future<MemberProfile?> getMember(String id) async => _directory.get(id);

  @override
  Future<List<MemberProfile>> getCommunityMembers(String communityId) async {
    final items = await _api.getAllItems('/communities/$communityId/members');
    return [
      for (final j in items)
        if (!_isBlocked(j['id'] as String))
          memberFromApi(j, remember: _directory),
    ];
  }
}
