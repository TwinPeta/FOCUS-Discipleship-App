import '../../../core/network/api_client.dart';
import '../domain/community.dart';
import '../domain/person.dart';
import 'community_api_mapper.dart';
import 'community_repository.dart';

/// [CommunityRepository] backed by the FCU API. The API scopes everything to
/// the signed-in user's institution, so the institution arguments are unused.
class RemoteCommunityRepository implements CommunityRepository {
  RemoteCommunityRepository(this._api);

  final ApiClient _api;

  @override
  Future<Community> getGeneralCommunity(
    String institutionId,
    String institutionName,
  ) async {
    final mine = objectOf(await _api.get('/me/communities'));
    final general = objectOf(mine?['general']);
    final summary = objectOf(general?['community']);
    final id = summary?['id'] as String?;
    if (id == null) {
      throw StateError('No General community for this account yet.');
    }
    return getCommunityById(id);
  }

  @override
  Future<List<Community>> getSpecificCommunities(String institutionId) async {
    final items = await _api.getAllItems(
      '/communities',
      query: {'type': 'specific'},
    );
    return items.map(communityFromApi).toList();
  }

  @override
  Future<Community> getCommunityById(String id) async {
    final json = objectOf(await _api.get('/communities/$id'));
    if (json == null) throw StateError('Unknown community: $id');
    return communityFromApi(json);
  }

  @override
  Future<List<Person>> getMembers(String communityId) async {
    final items = await _api.getAllItems('/communities/$communityId/members');
    return items.map(personFromApi).toList();
  }
}
