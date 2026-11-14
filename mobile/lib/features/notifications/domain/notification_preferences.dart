import 'app_notification.dart';

/// The switchable groups on Notification settings (screen 45).
enum NotificationCategory {
  joinRequestUpdates('Join request updates'),
  replies('Replies and comments'),
  prayerResponses('Prayer responses'),
  announcements('Announcements'),
  meetingReminders('Meeting reminders'),
  inactivityReminders('Inactivity reminders');

  const NotificationCategory(this.label);
  final String label;

  /// The category a type belongs to; null means it cannot be muted
  /// (moderator warnings always reach the member).
  static NotificationCategory? of(NotificationType type) => switch (type) {
    NotificationType.requestApproved ||
    NotificationType.requestDeclined => joinRequestUpdates,
    NotificationType.commentReply => replies,
    NotificationType.prayedForYou ||
    NotificationType.prayerResponse => prayerResponses,
    NotificationType.announcement => announcements,
    NotificationType.meetingReminder => meetingReminders,
    NotificationType.inactivity => inactivityReminders,
    NotificationType.moderatorWarning => null,
  };
}

/// Delivery channels a member can switch. Push is out of scope for now; it
/// becomes one more value here plus a [NotificationChannel] implementation.
enum DeliveryChannel {
  inApp('In-app'),
  email('Email');

  const DeliveryChannel(this.label);
  final String label;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.channels = const {DeliveryChannel.inApp, DeliveryChannel.email},
    this.muted = const {NotificationCategory.inactivityReminders},
  });

  /// Enabled channels (defaults: in-app and email on).
  final Set<DeliveryChannel> channels;

  /// Muted categories (default: only inactivity reminders).
  final Set<NotificationCategory> muted;

  static const defaults = NotificationPreferences();

  bool isEnabled(NotificationCategory c) => !muted.contains(c);
  bool usesChannel(DeliveryChannel c) => channels.contains(c);

  /// Whether a notification of [type] should be created at all. Muted
  /// categories are never recorded; unmutable types always are.
  bool allows(NotificationType type) {
    final category = NotificationCategory.of(type);
    return category == null || isEnabled(category);
  }

  NotificationPreferences withCategory(NotificationCategory c, bool on) =>
      NotificationPreferences(
        channels: channels,
        muted: on ? ({...muted}..remove(c)) : {...muted, c},
      );

  NotificationPreferences withChannel(DeliveryChannel c, bool on) =>
      NotificationPreferences(
        channels: on ? {...channels, c} : ({...channels}..remove(c)),
        muted: muted,
      );
}
