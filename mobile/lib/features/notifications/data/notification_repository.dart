import '../domain/app_notification.dart';
import '../domain/notification_preferences.dart';

abstract class NotificationRepository {
  /// The signed-in user's notifications, newest first.
  Future<List<AppNotification>> getNotifications();

  /// Another user's notifications (e.g. a student a super-mentor approved),
  /// newest first. A real backend delivers these to that user's device.
  Future<List<AppNotification>> getNotificationsFor(String recipientId);

  /// Records a notification for [recipientId] (null = the signed-in user)
  /// and delivers it on their enabled channels. Returns null, recording
  /// nothing, when the recipient muted the type's category or turned the
  /// in-app channel off; moderator warnings are always recorded.
  Future<AppNotification?> add({
    required NotificationType type,
    required String title,
    required String targetRoute,
    String? body,
    String? recipientId,
  });
  Future<void> markRead(String id);
  Future<void> markAllRead();

  /// [recipientId] null means the signed-in user.
  Future<NotificationPreferences> getPreferences({String? recipientId});
  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences, {
    String? recipientId,
  });
}
