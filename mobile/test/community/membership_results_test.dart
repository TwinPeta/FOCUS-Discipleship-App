import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

void main() {
  late FakeNotificationRepository notifications;
  late FakeMembershipRepository repo;
  setUp(() {
    notifications = FakeNotificationRepository(latency: Duration.zero);
    repo = FakeMembershipRepository(
      latency: Duration.zero,
      notifications: notifications,
    );
  });

  test(
    'approve: unseen result + notification, then marked seen once',
    () async {
      await repo.requestToJoin('growth-circle');
      final approved = await repo.debugApprove();
      expect(approved.status, MembershipStatus.approved);
      expect(approved.hasUnseenResult, isTrue);
      final items = await notifications.getNotifications();
      expect(items.single.type, NotificationType.requestApproved);
      expect(items.single.targetRoute, '/request/approved');
      expect(items.single.isRead, isFalse);

      final seen = await repo.markResultSeen();
      expect(seen.hasUnseenResult, isFalse);
      expect(seen.status, MembershipStatus.approved);
    },
  );

  test(
    'decline keeps the message; choosing another caregroup resets to none',
    () async {
      await repo.requestToJoin('growth-circle');
      final declined = await repo.reject(message: 'Group is full');
      expect(declined.status, MembershipStatus.rejected);
      expect(declined.message, 'Group is full');
      expect(declined.hasUnseenResult, isTrue);
      expect(
        (await notifications.getNotifications()).single.type,
        NotificationType.requestDeclined,
      );
      expect((await repo.clear()).status, MembershipStatus.none);
    },
  );

  test('leave is approved -> none only', () async {
    await repo.requestToJoin('growth-circle');
    expect(repo.leave, throwsA(isA<IllegalMembershipTransition>()));
    await repo.debugApprove();
    final left = await repo.leave();
    expect(left, same(Membership.empty));
    // After leaving, another community can be requested.
    expect(
      (await repo.requestToJoin('freshers-connect')).status,
      MembershipStatus.pending,
    );
  });

  testWidgets('the approved result opens once from the hub, then never again', (
    tester,
  ) async {
    final app = await pumpFcuApp(
      tester,
      membership: MembershipStatus.approved,
      resultSeen: false,
    );
    await goTo(tester, app, '/communities');
    await settle(tester);
    expect(find.text('You are in!'), findsOneWidget);

    await goTo(tester, app, '/communities');
    await settle(tester);
    expect(find.text('You are in!'), findsNothing);
  });

  testWidgets('the declined result offers another caregroup', (tester) async {
    final app = await pumpFcuApp(
      tester,
      membership: MembershipStatus.rejected,
      resultSeen: false,
    );
    await goTo(tester, app, '/communities');
    await settle(tester);
    expect(find.text('Request not accepted'), findsOneWidget);
    expect(find.textContaining('Group is full'), findsOneWidget);
    await tester.tap(find.text('Choose another caregroup'));
    await settle(tester);
    expect(find.text('Request not accepted'), findsNothing);
  });
}
