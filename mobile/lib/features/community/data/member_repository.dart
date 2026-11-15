import '../domain/member_profile.dart';

/// Public member profiles (screen 43) and community rosters with usernames
/// (screen 54).
abstract class MemberRepository {
  /// Null for an unknown id. Blocked people are still returned, so the
  /// blocked list (screen 55) can name them; screens decide what to show.
  Future<MemberProfile?> getMember(String id);

  /// The community's members with their profiles, people the user blocked
  /// left out.
  Future<List<MemberProfile>> getCommunityMembers(String communityId);
}
