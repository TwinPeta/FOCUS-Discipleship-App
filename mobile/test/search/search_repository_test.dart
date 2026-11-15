import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/community/data/community_repository.dart';
import 'package:focus_1/features/community/data/member_repository.dart';
import 'package:focus_1/features/search/data/search_repository.dart';
import 'package:focus_1/features/search/domain/search_results.dart';

void main() {
  const scope = SearchScope(
    institutionId: 'mak',
    institutionName: 'Makerere University',
    memberOfCommunityIds: ['growth-circle'],
    myId: 'me',
  );

  ClientSideSearchRepository repo({Set<String> blocked = const {}}) {
    final communities = FakeCommunityRepository();
    return ClientSideSearchRepository(
      communities: communities,
      members: FakeMemberRepository(
        latency: Duration.zero,
        roster: communities.getMembers,
      ),
      isBlocked: blocked.contains,
    );
  }

  test('matches community names case-insensitively', () async {
    final r = await repo().search('CIRCLE', scope);
    final names = r.communities.map((c) => c.name);
    expect(names, containsAll(['Growth Circle', 'Life & Faith Circle']));
    expect(names, isNot(contains('Freshers Connect')));
  });

  test('matches people by name and by username', () async {
    final byName = await repo().search('okello', scope);
    expect(byName.people.map((m) => m.person.id), ['m-1']);

    final byUsername = await repo().search('grace.nam', scope);
    expect(byUsername.people.map((m) => m.person.id), ['sm-1']);
  });

  test('blocked users are excluded', () async {
    final r = await repo(blocked: {'m-1'}).search('okello', scope);
    expect(r.people, isEmpty);
  });

  test('a blank query returns no results', () async {
    final r = await repo().search('   ', scope);
    expect(r.isEmpty, isTrue);
  });

  test('people come only from the communities in scope', () async {
    const none = SearchScope(
      institutionId: 'mak',
      institutionName: 'Makerere University',
    );
    final r = await repo().search('okello', none);
    expect(r.people, isEmpty);
  });
}
