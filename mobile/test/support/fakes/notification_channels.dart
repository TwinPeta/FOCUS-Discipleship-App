import 'package:focus_1/features/notifications/data/notification_channels.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:focus_1/features/notifications/domain/notification_preferences.dart';

/// Stand-in for an email service: records what would be sent.
class FakeEmailChannel implements NotificationChannel {
  final List<AppNotification> sent = [];

  @override
  DeliveryChannel get channel => DeliveryChannel.email;

  @override
  Future<void> deliver(AppNotification notification) async {
    sent.add(notification);
  }
}
