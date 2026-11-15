import '../domain/join_request.dart';
import '../domain/user_role.dart';

/// The super-mentor's queue of join requests for one community. Every call
/// takes the actor's role and throws [NotSuperMentor] unless it is
/// [UserRole.superMentor], so the rule holds even if the UI is bypassed.
abstract class JoinRequestRepository {
  /// Pending requests for [communityId], oldest first.
  Future<List<JoinRequest>> getPending(
    String communityId, {
    required UserRole? actorRole,
  });

  /// pending -> approved, and notifies the student. Throws
  /// [StudentAlreadyInCommunity] when the student already has a specific
  /// community.
  Future<JoinRequest> approve(String id, {required UserRole? actorRole});

  /// pending -> declined with an optional [message], and notifies the
  /// student.
  Future<JoinRequest> decline(
    String id, {
    required UserRole? actorRole,
    String? message,
  });
}
