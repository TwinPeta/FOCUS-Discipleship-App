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
    final added = await ref
        .read(notificationRepositoryProvider)
        .add(type: type, title: title, targetRoute: route);
    ref.invalidate(notificationsProvider);
    return added == null
        ? 'Not added: muted in Notification settings'
        : 'Notification added';
  },
);

final notificationDebugScenarios = <DebugScenario>[
  _emit(
    'Someone prayed for my request',
    NotificationType.prayedForYou,
    '8 people prayed for your request',
    '/prayer/growth-circle-prayer-1',
  ),
  _emit(
    'Prayer response',
    NotificationType.prayerResponse,
    'Someone responded to your prayer request',
    '/prayer/growth-circle-prayer-1',
  ),
  _emit(
    'Reply to my post',
    NotificationType.commentReply,
    'Someone commented on your post',
    '/post/growth-circle-post-1',
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
    '/community/growth-circle/meetings',
  ),
  _emit(
    'Inactivity nudge',
    NotificationType.inactivity,
    'We missed you this week. See what your community shared.',
    '/general-feed',
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
