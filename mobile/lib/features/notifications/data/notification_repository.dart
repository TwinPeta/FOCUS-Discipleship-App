import '../domain/app_notification.dart';

abstract class NotificationRepository {
  /// The signed-in user's notifications, newest first.
  Future<List<AppNotification>> getNotifications();

  /// Another user's notifications (e.g. a student a super-mentor approved),
  /// newest first. A real backend delivers these to that user's device.
  Future<List<AppNotification>> getNotificationsFor(String recipientId);

  /// [recipientId] null means the signed-in user.
  Future<AppNotification> add({
    required NotificationType type,
    required String title,
    required String targetRoute,
    String? body,
    String? recipientId,
  });
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    this.latency = const Duration(milliseconds: 300),
  });

  final Duration latency;
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

  @override
  Future<AppNotification> add({
    required NotificationType type,
    required String title,
    required String targetRoute,
    String? body,
    String? recipientId,
  }) async {
    // Recording is synchronous so callers emitting "at the source" never
    // race the screen that reads it next.
    final item = AppNotification(
      id: 'notif-${++_counter}',
      type: type,
      title: title,
      body: body,
      targetRoute: targetRoute,
      createdAt: DateTime.now(),
      recipientId: recipientId,
    );
    _items.add(item);
    return item;
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
}
