import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../community/domain/member_profile.dart';
import '../../community/domain/membership.dart';
import '../../community/domain/person.dart';
import '../../community/presentation/providers/member_providers.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/search_repository.dart';
import '../../feed/domain/post.dart';
import '../domain/search_results.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return ClientSideSearchRepository(
    communities: ref.watch(communityRepositoryProvider),
    members: ref.watch(memberRepositoryProvider),
    isBlocked: ref.read(moderationRepositoryProvider).isBlocked,
  );
});

/// Results for one committed (debounced) query.
final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>((ref, query) async {
      if (query.trim().isEmpty) return SearchResults.empty;
      final profile = ref.watch(currentProfileProvider);
      final institutionId = ref.watch(currentInstitutionIdProvider);
      if (profile == null || institutionId == null) {
        return SearchResults.empty;
      }
      final membership = await ref.watch(membershipProvider.future);
      final general = await ref.watch(generalCommunityProvider.future);
      final memberOf = [
        general.id,
        if (membership.status == MembershipStatus.approved &&
            membership.communityId != null)
          membership.communityId!,
      ];
      final found = await ref
          .watch(searchRepositoryProvider)
          .search(
            query,
            SearchScope(
              institutionId: institutionId,
              institutionName: profile.institutionName,
              memberOfCommunityIds: memberOf,
              myId: profile.id,
            ),
          );
      // Posts come from the server's post search. If it fails (or is not
      // deployed yet), communities and people still show.
      var posts = const <Post>[];
      try {
        posts = await ref.watch(postRepositoryProvider).searchPosts(query);
      } catch (_) {}
      return SearchResults(
        communities: found.communities,
        people: found.people,
        posts: posts,
      );
    });

/// Recent searches, newest first. Session-only (in memory), capped at
/// [RecentSearches.max].
class RecentSearches extends Notifier<List<String>> {
  static const max = 8;

  @override
  List<String> build() => const [];

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final rest = state.where((s) => s.toLowerCase() != q.toLowerCase());
    state = [q, ...rest].take(max).toList();
  }

  void clear() => state = const [];
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

/// Screen 62 before typing: a few of the campus's communities and the
/// mentors of the member's own community.
final searchSuggestionsProvider = FutureProvider.autoDispose<SearchResults>((
  ref,
) async {
  final communities = await ref.watch(specificCommunitiesProvider.future);
  final membership = await ref.watch(membershipProvider.future);
  final mine = membership.status == MembershipStatus.approved
      ? membership.communityId
      : null;
  final leaders = mine == null
      ? const <MemberProfile>[]
      : (await ref.watch(communityMemberProfilesProvider(mine).future))
            .where((m) => m.person.role != PersonRole.member)
            .toList();
  return SearchResults(
    communities: communities.take(3).toList(),
    people: leaders.take(3).toList(),
  );
});
