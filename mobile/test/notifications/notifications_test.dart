import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/utils/date_utils.dart';
import 'package:focus_1/core/widgets/switch_row.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:focus_1/features/notifications/domain/notification_preferences.dart';
import 'package:focus_1/features/notifications/presentation/notification_providers.dart';
import 'package:focus_1/features/notifications/presentation/notification_settings_screen.dart';
import 'package:focus_1/features/notifications/presentation/notifications_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

void main() {
  late FakeEmailChannel email;
  late FakeNotificationRepository repo;

  setUp(() {
    email = FakeEmailChannel();
    repo = FakeNotificationRepository(
      latency: Duration.zero,
      channels: [email],
    );
  });

  Future<AppNotification?> add(NotificationType type, {String? to}) => repo.add(
    type: type,
    title: type.name,
    targetRoute: '/x',
    recipientId: to,
  );

  group('preferences and muting', () {
    test('defaults: both channels on, only inactivity muted', () async {
      final p = await repo.getPreferences();
      expect(p.usesChannel(DeliveryChannel.inApp), isTrue);
      expect(p.usesChannel(DeliveryChannel.email), isTrue);
      expect(NotificationCategory.values.where((c) => !p.isEnabled(c)), [
        NotificationCategory.inactivityReminders,
      ]);
    });

    test('a muted category is never recorded or emailed', () async {
      expect(await add(NotificationType.inactivity), isNull);
      final p = await repo.getPreferences();
      await repo.savePreferences(
        p.withCategory(NotificationCategory.prayerResponses, false),
      );
      expect(await add(NotificationType.prayedForYou), isNull);
      expect(await add(NotificationType.prayerResponse), isNull);
      expect(await add(NotificationType.announcement), isNotNull);
      expect((await repo.getNotifications()).map((n) => n.type), [
        NotificationType.announcement,
      ]);
      expect(email.sent.map((n) => n.type), [NotificationType.announcement]);
    });

    test('unmuting lets new notifications through again', () async {
      final p = await repo.getPreferences();
      await repo.savePreferences(
        p.withCategory(NotificationCategory.inactivityReminders, true),
      );
      expect(await add(NotificationType.inactivity), isNotNull);
    });

    test('moderator warnings cannot be muted, even with in-app off', () async {
      var p = await repo.getPreferences();
      for (final c in NotificationCategory.values) {
        p = p.withCategory(c, false);
      }
      await repo.savePreferences(p.withChannel(DeliveryChannel.inApp, false));
      expect(await add(NotificationType.moderatorWarning), isNotNull);
      expect(await repo.getNotifications(), hasLength(1));
    });

    test('in-app off: nothing listed, email still sent', () async {
      final p = await repo.getPreferences();
      await repo.savePreferences(p.withChannel(DeliveryChannel.inApp, false));
      expect(await add(NotificationType.announcement), isNull);
      expect(await repo.getNotifications(), isEmpty);
      expect(email.sent, hasLength(1));
    });

    test('email off: listed in-app, not emailed', () async {
      final p = await repo.getPreferences();
      await repo.savePreferences(p.withChannel(DeliveryChannel.email, false));
      expect(await add(NotificationType.announcement), isNotNull);
      expect(email.sent, isEmpty);
    });

    test("another user's settings are their own", () async {
      final p = await repo.getPreferences(recipientId: 'student-1');
      await repo.savePreferences(
        p.withCategory(NotificationCategory.joinRequestUpdates, false),
        recipientId: 'student-1',
      );
      expect(
        await add(NotificationType.requestApproved, to: 'student-1'),
        isNull,
      );
      expect(await add(NotificationType.requestApproved), isNotNull);
    });

    test('every type except warnings maps to a category', () {
      for (final t in NotificationType.values) {
        expect(
          NotificationCategory.of(t) == null,
          t == NotificationType.moderatorWarning,
          reason: t.name,
        );
      }
    });
  });

  group('read state', () {
    test('markRead and markAllRead', () async {
      final a = (await add(NotificationType.announcement))!;
      await add(NotificationType.meetingReminder);
      await repo.markRead(a.id);
      var all = await repo.getNotifications();
      expect(all.where((n) => !n.isRead), hasLength(1));
      await repo.markAllRead();
      all = await repo.getNotifications();
      expect(all.every((n) => n.isRead), isTrue);
    });
  });

  test('formatNotificationTime', () {
    final now = DateTime(2026, 11, 14, 18); // a Saturday
    String f(DateTime d) => formatNotificationTime(d, clock: now);
    expect(f(DateTime(2026, 11, 14, 9, 5)), 'Today · 9:05');
    expect(f(DateTime(2026, 11, 13, 22)), 'Yesterday');
    expect(f(DateTime(2026, 11, 9, 8)), 'Mon');
    expect(f(DateTime(2026, 11, 1)), '1/11/2026');
  });

  testWidgets('screen 44: sections, tap marks read and opens the target', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    final notifications = container.read(notificationRepositoryProvider);
    await tester.runAsync(() async {
      final old = await notifications.add(
        type: NotificationType.meetingReminder,
        title: 'Your caregroup meets tomorrow',
        targetRoute: '/communities',
      );
      await notifications.markRead(old!.id);
      await notifications.add(
        type: NotificationType.announcement,
        title: 'New announcement',
        targetRoute: '/general-feed',
      );
    });
    container.invalidate(notificationsProvider);
    await goTo(tester, container, '/notifications');

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);
    expect(container.read(unreadNotificationCountProvider), 1);

    await tester.tap(find.text('New announcement'));
    await settle(tester, steps: 12);
    expect(find.byType(NotificationsScreen), findsNothing);
    expect(container.read(unreadNotificationCountProvider), 0);
    // Let the opened feed finish loading before the test ends.
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
  });

  testWidgets('screen 44: empty state', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/notifications');
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('screen 45: toggles persist and mute new notifications', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/notifications/settings');

    expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    expect(find.text('Choose what you hear about.'), findsOneWidget);
    expect(find.byType(SwitchRow), findsNWidgets(8));

    await tester.tap(find.text('Announcements'));
    await settle(tester);
    final repo = container.read(notificationRepositoryProvider);
    late NotificationPreferences saved;
    late AppNotification? added;
    await tester.runAsync(() async {
      saved = await repo.getPreferences();
      added = await repo.add(
        type: NotificationType.announcement,
        title: 'muted',
        targetRoute: '/general-feed',
      );
    });
    expect(saved.isEnabled(NotificationCategory.announcements), isFalse);
    expect(added, isNull);
  });
}
