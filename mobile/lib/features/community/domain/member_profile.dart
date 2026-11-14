import '../../activity/domain/badge.dart';
import 'person.dart';

/// What another member sees on a profile (screen 43). Never carries the
/// person's activity history: only badges they have earned.
class MemberProfile {
  const MemberProfile({
    required this.person,
    required this.username,
    this.bio,
    this.institution,
    this.communityName,
    this.badges = const [],
  });

  final Person person;
  final String username;
  final String? bio;

  /// Null when the directory does not know it; members of your communities
  /// are on your campus, so screens fall back to the viewer's institution.
  final String? institution;
  final String? communityName;

  /// Earned badges only.
  final List<AppBadge> badges;

  /// Mentors and super-mentors are vetted by the admin team.
  bool get verified => person.role != PersonRole.member;
}
