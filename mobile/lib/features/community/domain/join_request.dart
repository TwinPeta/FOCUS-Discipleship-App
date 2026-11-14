enum JoinRequestStatus { pending, approved, declined }

/// A student's request to join one specific community, as the community's
/// super-mentor sees it on screen 31.
class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.communityId,
    required this.studentId,
    required this.studentName,
    required this.username,
    required this.institution,
    required this.requestedAt,
    this.status = JoinRequestStatus.pending,
    this.message,
    this.seen = false,
    this.existingCommunityName,
  });

  final String id;
  final String communityId;
  final String studentId;
  final String studentName;
  final String username;
  final String institution;
  final DateTime requestedAt;
  final JoinRequestStatus status;

  /// The super-mentor's optional note when declining.
  final String? message;

  /// The student has seen the result (approved/declined) screen.
  final bool seen;

  /// Set when the student is already in another specific community; such a
  /// request cannot be approved (one specific community per student).
  final String? existingCommunityName;

  bool get isPending => status == JoinRequestStatus.pending;
  bool get canApprove => isPending && existingCommunityName == null;

  JoinRequest copyWith({
    JoinRequestStatus? status,
    String? message,
    bool? seen,
    String? existingCommunityName,
  }) {
    return JoinRequest(
      id: id,
      communityId: communityId,
      studentId: studentId,
      studentName: studentName,
      username: username,
      institution: institution,
      requestedAt: requestedAt,
      status: status ?? this.status,
      message: message ?? this.message,
      seen: seen ?? this.seen,
      existingCommunityName:
          existingCommunityName ?? this.existingCommunityName,
    );
  }
}

/// Approving would put a student in a second specific community.
class StudentAlreadyInCommunity implements Exception {
  const StudentAlreadyInCommunity(this.communityName);
  final String communityName;
  @override
  String toString() => 'StudentAlreadyInCommunity($communityName)';
}

/// The request was already approved or declined.
class JoinRequestNotPending implements Exception {
  const JoinRequestNotPending(this.id);
  final String id;
  @override
  String toString() => 'JoinRequestNotPending($id)';
}
