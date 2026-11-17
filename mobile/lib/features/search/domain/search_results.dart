import '../../community/domain/community.dart';
import '../../community/domain/member_profile.dart';
import '../../feed/domain/post.dart';

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
  const SearchResults({
    this.communities = const [],
    this.people = const [],
    this.posts = const [],
  });

  static const empty = SearchResults();

  final List<Community> communities;
  final List<MemberProfile> people;

  /// Posts and questions whose text matches, in the member's communities.
  final List<Post> posts;

  bool get isEmpty => communities.isEmpty && people.isEmpty && posts.isEmpty;
}
