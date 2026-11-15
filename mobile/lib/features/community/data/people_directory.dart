import '../domain/member_profile.dart';

/// People the app has met through the API (community rosters, post authors),
/// so a tapped name can open a profile. The API has no "get user by id"
/// endpoint, so profiles are remembered as they appear.
class PeopleDirectory {
  final Map<String, MemberProfile> _byId = {};

  void put(MemberProfile profile) => _byId[profile.person.id] = profile;

  MemberProfile? get(String id) => _byId[id];
}
