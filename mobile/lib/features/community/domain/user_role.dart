/// The current user's role inside one community membership. Drives
/// role-only controls (e.g. the super-mentor "Manage" button).
enum UserRole { student, mentor, superMentor }

/// The acting user is not the super-mentor of this community. Thrown by
/// repositories behind the super-mentor tools (screens 30-32).
class NotSuperMentor implements Exception {
  const NotSuperMentor(this.communityId);
  final String communityId;
  @override
  String toString() => 'NotSuperMentor($communityId)';
}
