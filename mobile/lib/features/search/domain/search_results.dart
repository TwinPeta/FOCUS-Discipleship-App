import '../../community/domain/community.dart';
import '../../community/domain/member_profile.dart';

/// What the signed-in user may search over: their institution's
/// communities, and the people in the communities they belong to.
class SearchScope {
  const SearchScope({
    required this.institutionId,
    required this.institutionName,
    this.memberOfCommunityIds = const [],
    this.myId,
  });

  final String institutionId;
  final String institutionName;

  /// Communities whose members appear under People.
  final List<String> memberOfCommunityIds;

  /// The searcher, left out of People.
  final String? myId;
}

/// Search screen (62) results, in display order.
class SearchResults {
  const SearchResults({this.communities = const [], this.people = const []});

  static const empty = SearchResults();

  final List<Community> communities;
  final List<MemberProfile> people;

  bool get isEmpty => communities.isEmpty && people.isEmpty;
}
