import '../domain/membership.dart';

/// The signed-in user's single specific-community membership. Every write
/// goes through [Membership.transitionTo], so illegal moves throw here
/// regardless of what the UI allows.
abstract class MembershipRepository {
  Future<Membership> getMembership();

  /// Idempotent for the same community: a second call while that request is
  /// pending returns the existing request. Throws [MembershipLimitReached]
  /// when a request for another community is pending or approved.
  Future<Membership> requestToJoin(String communityId);

  /// Debug-only prototype hook standing in for super-mentor approval.
  Future<Membership> debugApprove();

  /// The super-mentor declines, optionally with a [message].
  Future<Membership> reject({String? message});

  /// approved -> none. Throws for any other status.
  Future<Membership> leave();

  /// Back to `none` (acknowledge a rejection, or reset in debug).
  Future<Membership> clear();

  /// The one-time result screen (approved/declined) has been shown.
  Future<Membership> markResultSeen();
}
