import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/route_guards.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/community/domain/join_request.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/community/presentation/join_requests_screen.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

const _sm = UserRole.superMentor;
const _community = 'growth-circle';

void main() {
  late FakeNotificationRepository notifications;
  late FakeJoinRequestRepository repo;

  setUp(() {
    notifications = FakeNotificationRepository(latency: Duration.zero);
    repo = FakeJoinRequestRepository(
      latency: Duration.zero,
      notifications: notifications,
    );
  });

  group('JoinRequestRepository', () {
    test('only super-mentors can list, approve or decline', () async {
      for (final role in [null, UserRole.student, UserRole.mentor]) {
        await expectLater(
          repo.getPending(_community, actorRole: role),
          throwsA(isA<NotSuperMentor>()),
        );
        await expectLater(
          repo.approve('jr-1', actorRole: role),
          throwsA(isA<NotSuperMentor>()),
        );
        await expectLater(
          repo.decline('jr-1', actorRole: role),
          throwsA(isA<NotSuperMentor>()),
        );
      }
    });

    test('pending list is oldest first', () async {
      final pending = await repo.getPending(_community, actorRole: _sm);
      expect(pending.map((r) => r.id), ['jr-1', 'jr-2', 'jr-3', 'jr-4']);
    });

    test('approve leaves the queue and notifies only the student', () async {
      final r = await repo.approve('jr-1', actorRole: _sm);
      expect(r.status, JoinRequestStatus.approved);
      expect(r.seen, isFalse);
      final pending = await repo.getPending(_community, actorRole: _sm);
      expect(pending.map((r) => r.id), isNot(contains('jr-1')));

      final sent = await notifications.getNotificationsFor('student-1');
      expect(sent.single.type, NotificationType.requestApproved);
      expect(sent.single.targetRoute, '/request/approved');
      // The super-mentor's own inbox is untouched.
      expect(await notifications.getNotifications(), isEmpty);
    });

    test('decline keeps the optional message and notifies', () async {
      final r = await repo.decline(
        'jr-2',
        actorRole: _sm,
        message: '  Group is full  ',
      );
      expect(r.status, JoinRequestStatus.declined);
      expect(r.message, 'Group is full');
      final sent = await notifications.getNotificationsFor('student-2');
      expect(sent.single.type, NotificationType.requestDeclined);
      expect(sent.single.body, 'Group is full');

      final blank = await repo.decline('jr-4', actorRole: _sm, message: ' ');
      expect(blank.message, isNull);
    });

    test('a student already in another caregroup cannot be approved', () async {
      final pending = await repo.getPending(_community, actorRole: _sm);
      final peter = pending.firstWhere((r) => r.id == 'jr-3');
      expect(peter.canApprove, isFalse);
      await expectLater(
        repo.approve('jr-3', actorRole: _sm),
        throwsA(isA<StudentAlreadyInCommunity>()),
      );
      // Declining is still allowed.
      final r = await repo.decline('jr-3', actorRole: _sm);
      expect(r.status, JoinRequestStatus.declined);
    });

    test(
      'a decided request cannot be decided again; no double submit',
      () async {
        await repo.approve('jr-1', actorRole: _sm);
        await expectLater(
          repo.decline('jr-1', actorRole: _sm),
          throwsA(isA<JoinRequestNotPending>()),
        );

        final slow = FakeJoinRequestRepository(
          latency: const Duration(milliseconds: 10),
          notifications: notifications,
        );
        final first = slow.approve('jr-2', actorRole: _sm);
        await expectLater(
          slow.approve('jr-2', actorRole: _sm),
          throwsA(isA<JoinRequestNotPending>()),
        );
        await first;
        expect(
          await notifications.getNotificationsFor('student-2'),
          hasLength(1),
        );
      },
    );
  });

  test('guard: only super-mentors reach /community/:id/manage/requests', () {
    final profile = testProfile;
    GuardContext ctx(UserRole role) => GuardContext(
      location: Uri.parse('/community/$_community/manage/requests'),
      profile: AsyncValue.data(profile),
      membership: const AsyncValue.data(
        Membership(communityId: _community, status: MembershipStatus.approved),
      ),
      session: const AsyncValue.data(
        AuthSession(accountId: 'u1', email: 't@fcu.test'),
      ),
      role: role,
    );
    expect(runGuards(ctx(UserRole.student)), '/community/$_community/feed');
    expect(runGuards(ctx(UserRole.superMentor)), isNull);
  });

  testWidgets('screen: approve removes the row; Already in disables Approve', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    container.read(debugRoleOverrideProvider.notifier).state = _sm;
    await goTo(tester, container, '/community/$_community/manage/requests');

    expect(find.byType(JoinRequestsScreen), findsOneWidget);
    expect(
      find.text('A student can be in only one specific caregroup.'),
      findsOneWidget,
    );
    expect(find.text('Already in Life & Faith Circle'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Approve').first);
    await settle(tester, steps: 12);
    expect(find.text('Brian Mugisha approved'), findsOneWidget);
    expect(find.text('Brian Mugisha'), findsNothing);
  });
}
