import '../../../core/debug/debug_scenario.dart';
import '../../../core/providers/repository_providers.dart';
import '../domain/app_notification.dart';
import 'notification_providers.dart';

DebugScenario _emit(
  String name,
  NotificationType type,
  String title,
  String route,
) => DebugScenario(
  group: 'Notifications',
  name: name,
  description: 'Adds a "$title" notification (the bell shows a dot).',
  run: (ref, _) async {
    await ref
        .read(notificationRepositoryProvider)
        .add(type: type, title: title, targetRoute: route);
    ref.invalidate(notificationsProvider);
    return 'Notification added';
  },
);

final notificationDebugScenarios = <DebugScenario>[
  _emit(
    'Someone prayed for my request',
    NotificationType.prayedForYou,
    'Someone prayed for your request',
    '/communities',
  ),
  _emit(
    'Announcement',
    NotificationType.announcement,
    'New announcement from your campus team',
    '/general-feed',
  ),
  _emit(
    'Meeting reminder',
    NotificationType.meetingReminder,
    'Your community meets tomorrow',
    '/communities',
  ),
  _emit(
    'Inactivity nudge',
    NotificationType.inactivity,
    'We have missed you this week',
    '/communities',
  ),
  DebugScenario(
    group: 'Notifications',
    name: 'Mark all read',
    description: 'Clears the unread dot.',
    run: (ref, _) async {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      return 'All read';
    },
  ),
];
