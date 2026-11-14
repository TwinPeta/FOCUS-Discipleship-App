import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/features/activity/data/activity_repository.dart';
import 'package:focus_1/features/community/domain/community.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/community/presentation/join_requests_screen.dart';
import 'package:focus_1/features/community/presentation/manage_community_screen.dart';
import 'package:focus_1/features/community/presentation/providers/manage_providers.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);
  const leader = Person(id: 'sm', name: 'Leader', role: PersonRole.superMentor);
  const a = Person(id: 'a', name: 'Active', role: PersonRole.member);
  const q = Person(id: 'q', name: 'Quiet', role: PersonRole.member);
  const n = Person(id: 'n', name: 'Never', role: PersonRole.member);
  const edge = Person(id: 'e', name: 'Edge', role: PersonRole.member);

  group('membersToFollowUp', () {
    test('14+ days quiet or never active; leaders excluded; oldest first', () {
      final result = membersToFollowUp(
        [leader, a, q, n, edge],
        {
          'sm': now.subtract(const Duration(days: 60)),
          'a': now.subtract(const Duration(days: 13, hours: 23)),
          'q': now.subtract(const Duration(days: 30)),
          'e': now.subtract(const Duration(days: 14)),
        },
        now: now,
      );
      expect(result.map((p) => p.id), ['n', 'q', 'e']);
    });

    test('threshold is configurable', () {
      final result = membersToFollowUp(
        [a],
        {'a': now.subtract(const Duration(days: 3))},
        now: now,
        inactiveFor: const Duration(days: 2),
      );
      expect(result.single.id, 'a');
    });
  });

  test('last-active dates are for super-mentors only', () async {
    final repo = FakeActivityRepository(latency: Duration.zero);
    for (final role in [null, UserRole.student, UserRole.mentor]) {
      await expectLater(
        repo.lastActiveByMember('growth-circle', actorRole: role),
        throwsA(isA<NotSuperMentor>()),
      );
    }
    final map = await repo.lastActiveByMember(
      'growth-circle',
      actorRole: UserRole.superMentor,
    );
    expect(map.values, everyElement(isA<DateTime>()));
  });

  test('meetingSummary drops "Every" and joins the parts', () {
    const c = Community(
      id: 'c',
      name: 'C',
      initials: 'C',
      type: CommunityType.specific,
      institutionId: '',
      description: '',
      meetingDay: 'Every Tuesday',
      meetingTime: '5:00 PM',
      room: 'Room 204',
    );
    expect(meetingSummary(c), 'Tuesday · 5:00 PM · Room 204');
  });

  testWidgets('screen: live counters, follow-up sheet, link to 31', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    container.read(debugRoleOverrideProvider.notifier).state =
        UserRole.superMentor;
    await goTo(tester, container, '/community/growth-circle/manage');

    expect(find.byType(ManageCommunityScreen), findsOneWidget);
    expect(find.text('Manage Growth Circle'), findsOneWidget);
    expect(find.text('Only super-mentors see this.'), findsOneWidget);
    expect(find.bySemanticsLabel('Join requests, 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Reports to review, 3'), findsOneWidget);
    // Seed: Peter Ssentongo quiet for 21 days, Isaac Wandera never active.
    expect(find.bySemanticsLabel('Members to follow up, 2'), findsOneWidget);
    expect(
      find.text('Tuesday · 5:00 PM · Room 204, Student Centre'),
      findsOneWidget,
    );

    await tester.tap(find.text('Members to follow up'));
    await settle(tester);
    expect(find.text('Isaac Wandera'), findsOneWidget);
    expect(find.text('Peter Ssentongo'), findsOneWidget);
    expect(find.bySemanticsLabel('Message Isaac Wandera'), findsOneWidget);
    Navigator.of(tester.element(find.text('Isaac Wandera'))).pop();
    await settle(tester);

    await tester.tap(find.text('Join requests'));
    await settle(tester, steps: 12);
    expect(find.byType(JoinRequestsScreen), findsOneWidget);
  });

  testWidgets('students are sent back to the feed', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/community/growth-circle/manage');
    expect(find.byType(ManageCommunityScreen), findsNothing);
    expect(
      container.read(manageClockProvider)(),
      isA<DateTime>(),
    ); // clock is injectable
  });
}
