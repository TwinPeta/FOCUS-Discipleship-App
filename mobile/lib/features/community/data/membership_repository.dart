import '../domain/membership.dart';

abstract class MembershipRepository {
  Future<Membership> getMembership();
  Future<Membership> requestToJoin(String communityId);

  /// Debug-only prototype hook (see [kDebugMode] gating at the call site)
  /// standing in for the real super-mentor approval flow.
  Future<Membership> debugApprove();

  Future<Membership> reject();
  Future<Membership> clear();
}

class FakeMembershipRepository implements MembershipRepository {
  Membership _membership = Membership.empty;

  static const _latency = Duration(milliseconds: 400);

  @override
  Future<Membership> getMembership() async {
    await Future.delayed(_latency);
    return _membership;
  }

  @override
  Future<Membership> requestToJoin(String communityId) async {
    await Future.delayed(_latency);
    _membership = Membership(
      communityId: communityId,
      status: MembershipStatus.pending,
    );
    return _membership;
  }

  @override
  Future<Membership> debugApprove() async {
    await Future.delayed(_latency);
    _membership = _membership.copyWith(status: MembershipStatus.approved);
    return _membership;
  }

  @override
  Future<Membership> reject() async {
    await Future.delayed(_latency);
    _membership = _membership.copyWith(status: MembershipStatus.rejected);
    return _membership;
  }

  @override
  Future<Membership> clear() async {
    await Future.delayed(_latency);
    _membership = Membership.empty;
    return _membership;
  }
}
