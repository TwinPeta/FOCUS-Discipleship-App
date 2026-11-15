import '../domain/app_notification.dart';
import '../domain/notification_preferences.dart';

/// Delivers a recorded notification outside the app (email today, push
/// later). The in-app list is the repository itself, not a channel.
abstract class NotificationChannel {
  DeliveryChannel get channel;
  Future<void> deliver(AppNotification notification);
}
