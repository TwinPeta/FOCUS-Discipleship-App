import '../../community/data/community_repository.dart';
import '../../community/data/member_repository.dart';
import '../../community/domain/community.dart';
import '../../community/domain/member_profile.dart';
import '../domain/search_results.dart';

/// Search over communities and people (screen 62).
abstract class SearchRepository {
  /// A blank [query] returns [SearchResults.empty] without any calls.
  Future<SearchResults> search(String query, SearchScope scope);
}

/// Searches client-side over the existing community and member
/// repositories, so it works against both the fake and the real API.
///
/// TODO(J2): switch to the server search endpoint once the backend ships
/// it; this loads whole rosters and only sees the user's own communities.
class ClientSideSearchRepository implements SearchRepository {
  ClientSideSearchRepository({
    required this.communities,
    required this.members,
    required this.isBlocked,
  });

  final CommunityRepository communities;
  final MemberRepository members;
  final bool Function(String userId) isBlocked;

  @override
  Future<SearchResults> search(String query, SearchScope scope) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return SearchResults.empty;

    final general = communities.getGeneralCommunity(
      scope.institutionId,
      scope.institutionName,
    );
    final specific = communities.getSpecificCommunities(scope.institutionId);
    final communityList = <Community>[await general, ...await specific];

    final rosters = await Future.wait([
      for (final id in scope.memberOfCommunityIds.toSet())
        members.getCommunityMembers(id),
    ]);
    final seen = <String>{};
    final people = <MemberProfile>[];
    for (final roster in rosters) {
      for (final m in roster) {
        final id = m.person.id;
        if (id == scope.myId || isBlocked(id) || !seen.add(id)) continue;
        if (_matches(m, q)) people.add(m);
      }
    }
    people.sort((a, b) => a.person.name.compareTo(b.person.name));

    return SearchResults(
      communities: [
        for (final c in communityList)
          if (c.name.toLowerCase().contains(q)) c,
      ],
      people: people,
    );
  }

  static bool _matches(MemberProfile m, String q) =>
      m.person.name.toLowerCase().contains(q) ||
      m.username.toLowerCase().contains(q);
}
