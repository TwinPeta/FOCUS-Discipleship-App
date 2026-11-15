import '../../../core/network/api_client.dart';
import '../domain/membership.dart';
import 'membership_repository.dart';

/// [MembershipRepository] backed by the FCU API.
///
/// The server only knows "pending", "member" and "none"; the app's
/// approved/rejected result screens are worked out here. A pending request
/// seen earlier in this session that is now a membership (or was declined)
/// is an unseen result. Results that happened while the app was closed show
/// up in the notifications list instead (nothing is stored on the device).
class RemoteMembershipRepository implements MembershipRepository {
  RemoteMembershipRepository(this._api);

  final ApiClient _api;

  Membership _last = Membership.empty;
  bool _sawPending = false;
  bool _unseenResult = false;
  String? _rejectedRequestId;
  final Set<String> _acknowledged = {};
  Future<Membership>? _inFlightRequest;

  Future<Membership> _load() async {
    final mine = objectOf(await _api.get('/me/communities'));
    final specific = objectOf(mine?['specific']);
    if (specific != null) {
      final community = objectOf(specific['community']) ?? const {};
      final id = community['id'] as String?;
      if (specific['membership_status'] == 'pending') {
        _sawPending = true;
        return _last = Membership(
          communityId: id,
          status: MembershipStatus.pending,
        );
      }
      if (_sawPending) {
        _sawPending = false;
        _unseenResult = true;
      }
      return _last = Membership(
        communityId: id,
        status: MembershipStatus.approved,
        resultSeen: !_unseenResult,
      );
    }

    // No specific community: was the latest request declined?
    final requests = itemsOf(await _api.get('/me/join-requests'))
      ..sort(
        (a, b) => ((b['created_at'] as String?) ?? '').compareTo(
          (a['created_at'] as String?) ?? '',
        ),
      );
    final latest = requests.isEmpty ? null : requests.first;
    if (latest != null &&
        latest['status'] == 'rejected' &&
        !_acknowledged.contains(latest['id'])) {
      if (_sawPending) {
        _sawPending = false;
        _unseenResult = true;
      }
      _rejectedRequestId = latest['id'] as String?;
      final community = objectOf(latest['community']) ?? const {};
      return _last = Membership(
        communityId: community['id'] as String?,
        status: MembershipStatus.rejected,
        message: latest['note'] as String?,
        resultSeen: !_unseenResult,
      );
    }
    _sawPending = false;
    _unseenResult = false;
    return _last = Membership.empty;
  }

  @override
  Future<Membership> getMembership() => _load();

  @override
  Future<Membership> requestToJoin(String communityId) {
    // Two rapid taps share one in-flight request.
    return _inFlightRequest ??= _request(communityId)
        .whenComplete(() => _inFlightRequest = null);
  }

  Future<Membership> _request(String communityId) async {
    final current = await _load();
    if (current.status == MembershipStatus.pending &&
        current.communityId == communityId) {
      return current;
    }
    if (current.isActive) throw MembershipLimitReached(current.communityId);
    try {
      await _api.post('/communities/$communityId/join-requests');
    } on ApiException catch (e) {
      if (e.code == 'community_limit_reached') {
        // The server knows a request or membership this session did not
        // (made on another device, or approved meanwhile): reload it so the
        // caller can show the real state.
        final fresh = await _load();
        throw MembershipLimitReached(fresh.communityId);
      }
      rethrow;
    }
    _sawPending = true;
    _unseenResult = false;
    return _load();
  }

  /// Approval happens on the super-mentor's side; nothing to do here.
  @override
  Future<Membership> debugApprove() => _load();

  /// Declining happens on the super-mentor's side; nothing to do here.
  @override
  Future<Membership> reject({String? message}) => _load();

  /// `DELETE /join-requests/{id}` for the pending request. If the
  /// super-mentor decided it meanwhile (`409 not_pending`), the decision is
  /// returned instead.
  @override
  Future<Membership> cancelRequest() async {
    final current = await _load();
    if (current.status != MembershipStatus.pending) {
      throw IllegalMembershipTransition(current.status, MembershipStatus.none);
    }
    final pending = itemsOf(await _api.get('/me/join-requests')).where(
      (j) =>
          j['status'] == 'pending' &&
          (objectOf(j['community'])?['id'] as String?) == current.communityId,
    );
    if (pending.isNotEmpty) {
      try {
        await _api.delete('/join-requests/${pending.first['id']}');
      } on ApiException catch (e) {
        if (e.code != 'not_pending') rethrow;
        return _load();
      }
    }
    _sawPending = false;
    _unseenResult = false;
    return _load();
  }

  @override
  Future<Membership> leave() async {
    final current = await _load();
    if (current.status != MembershipStatus.approved ||
        current.communityId == null) {
      throw IllegalMembershipTransition(current.status, MembershipStatus.none);
    }
    await _api.delete('/communities/${current.communityId}/membership');
    _unseenResult = false;
    return _last = Membership.empty;
  }

  @override
  Future<Membership> markResultSeen() async {
    _unseenResult = false;
    return _last = _last.markResultSeen();
  }

  @override
  Future<Membership> clear() async {
    if (_last.status == MembershipStatus.rejected) {
      final id = _rejectedRequestId;
      if (id != null) _acknowledged.add(id);
      _unseenResult = false;
      return _last = Membership.empty;
    }
    return _last;
  }
}
