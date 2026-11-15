import 'package:focus_1/features/notifications/data/notification_channels.dart';
import 'package:focus_1/features/notifications/data/notification_repository.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:focus_1/features/notifications/domain/notification_preferences.dart';

import 'notification_channels.dart';

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    this.latency = const Duration(milliseconds: 300),
    List<NotificationChannel>? channels,
  }) : channels = channels ?? [FakeEmailChannel()];

  final Duration latency;

  /// Out-of-app delivery (email today; push can be added here).
  final List<NotificationChannel> channels;
  final Map<String?, NotificationPreferences> _preferences = {};
  final List<AppNotification> _items = [];
  var _counter = 0;

  @override
  Future<List<AppNotification>> getNotifications() =>
      _query((n) => n.recipientId == null);

  @override
  Future<List<AppNotification>> getNotificationsFor(String recipientId) =>
      _query((n) => n.recipientId == recipientId);

  Future<List<AppNotification>> _query(
    bool Function(AppNotification) test,
  ) async {
    await Future.delayed(latency);
    final sorted = _items.where(test).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  NotificationPreferences _prefsFor(String? recipientId) =>
      _preferences[recipientId] ?? NotificationPreferences.defaults;

  @override
  Future<AppNotification?> add({
    required NotificationType type,
    required String title,
    required String targetRoute,
    String? body,
    String? recipientId,
  }) async {
    // Recording is synchronous so callers emitting "at the source" never
    // race the screen that reads it next.
    final prefs = _prefsFor(recipientId);
    if (!prefs.allows(type)) return null;
    final unmutable = NotificationCategory.of(type) == null;
    final inApp = unmutable || prefs.usesChannel(DeliveryChannel.inApp);
    final item = AppNotification(
      id: 'notif-${++_counter}',
      type: type,
      title: title,
      body: body,
      targetRoute: targetRoute,
      createdAt: DateTime.now(),
      recipientId: recipientId,
    );
    if (inApp) _items.add(item);
    for (final c in channels) {
      if (prefs.usesChannel(c.channel)) await c.deliver(item);
    }
    return inApp ? item : null;
  }

  @override
  Future<void> markRead(String id) async {
    await Future.delayed(latency);
    final i = _items.indexWhere((n) => n.id == id);
    if (i != -1 && !_items[i].isRead) {
      _items[i] = _items[i].copyWith(readAt: DateTime.now());
    }
  }

  @override
  Future<void> markAllRead() async {
    await Future.delayed(latency);
    final now = DateTime.now();
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) _items[i] = _items[i].copyWith(readAt: now);
    }
  }

  @override
  Future<NotificationPreferences> getPreferences({String? recipientId}) async {
    await Future.delayed(latency);
    return _prefsFor(recipientId);
  }

  @override
  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences, {
    String? recipientId,
  }) async {
    await Future.delayed(latency);
    return _preferences[recipientId] = preferences;
  }
}
