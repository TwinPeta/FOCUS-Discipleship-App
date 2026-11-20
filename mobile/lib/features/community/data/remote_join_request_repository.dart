import '../../../core/network/api_client.dart';
import '../domain/join_request.dart';
import '../domain/user_role.dart';
import 'community_api_mapper.dart';
import 'join_request_repository.dart';

/// [JoinRequestRepository] backed by the FCU API. The server checks that the
/// caller really is the community's super-mentor; the role check here only
/// saves a round trip. The student is notified by the server.
class RemoteJoinRequestRepository implements JoinRequestRepository {
  RemoteJoinRequestRepository(this._api);

  final ApiClient _api;
  final Set<String> _inFlight = {};

  void _requireSuperMentor(UserRole? role, String communityId) {
    if (role != UserRole.superMentor) throw NotSuperMentor(communityId);
  }

  @override
  Future<List<JoinRequest>> getPending(
    String communityId, {
    required UserRole? actorRole,
  }) async {
    _requireSuperMentor(actorRole, communityId);
    try {
      final json = await _api.get(
        '/communities/$communityId/join-requests',
        query: {'status': 'pending'},
      );
      final list = itemsOf(json).map(joinRequestFromApi).toList()
        ..sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      return list;
    } on ApiException catch (e) {
      if (e.status == 403) throw NotSuperMentor(communityId);
      rethrow;
    }
  }

  @override
  Future<JoinRequest> approve(String id, {required UserRole? actorRole}) =>
      _decide(id, actorRole, 'approve');

  @override
  Future<JoinRequest> decline(
    String id, {
    required UserRole? actorRole,
    String? message,
  }) => _decide(id, actorRole, 'reject', note: message);

  Future<JoinRequest> _decide(
    String id,
    UserRole? actorRole,
    String decision, {
    String? note,
  }) async {
    // A second tap while the first is in flight is rejected, not repeated.
    if (!_inFlight.add(id)) throw JoinRequestNotPending(id);
    try {
      _requireSuperMentor(actorRole, '');
      final text = note?.trim();
      final json = await _api.post(
        '/join-requests/$id/decision',
        body: {
          'decision': decision,
          if (decision == 'reject' && text != null && text.isNotEmpty)
            'note': text,
        },
      );
      final map = objectOf(json);
      if (map == null) throw JoinRequestNotPending(id);
      return joinRequestFromApi(map);
    } on ApiException catch (e) {
      if (e.code == 'not_pending') throw JoinRequestNotPending(id);
      if (e.code == 'community_limit_reached') {
        // The server says which one: "This student already belongs to <caregroup>".
        final name = RegExp(r'belongs to (.+)$')
            .firstMatch(e.message ?? '')
            ?.group(1);
        throw StudentAlreadyInCommunity(name ?? 'another caregroup');
      }
      if (e.status == 403) throw const NotSuperMentor('');
      rethrow;
    } finally {
      _inFlight.remove(id);
    }
  }
}
