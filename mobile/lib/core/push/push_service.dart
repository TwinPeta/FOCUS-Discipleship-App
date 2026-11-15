import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/data/remote_notification_repository.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/presentation/notification_providers.dart';

/// The Android channel every FCU phone notification uses.
const pushChannelId = 'fcu_general';
const pushChannelName = 'FCU notifications';
const pushChannelDescription =
    'Join requests, replies, prayers, announcements and reminders';

/// A phone notification ready to show; [route] is where tapping it goes.
class PushMessage {
  const PushMessage({
    required this.id,
    required this.title,
    required this.route,
    this.body,
  });

  final int id;
  final String title;
  final String? body;
  final String route;
}

typedef ShowPush = Future<void> Function(PushMessage message);

/// Turns each `notification.created` realtime event into a phone
/// notification. Local only: there is no Firebase project or server sender
/// yet, so this runs while the app (and its socket) is alive. Skips types
/// the member muted (the same check as the unread count) and skips when the
/// member is already looking at the notifications screen.
class PushService {
  PushService({
    required this.show,
    required this.isAllowed,
    required this.isViewingNotifications,
    this.requestPermission,
  });

  final ShowPush show;
  final bool Function(NotificationType type) isAllowed;
  final bool Function() isViewingNotifications;
  final Future<bool?> Function()? requestPermission;

  bool _asked = false;
  bool _denied = false;

  /// The message [data] (a `notification.created` payload) would show, or
  /// null when it should be skipped.
  PushMessage? decide(Map<String, dynamic> data) {
    final type = RemoteNotificationRepository.typeOf(data['type'] as String?);
    if (type == null || !isAllowed(type)) return null;
    if (isViewingNotifications()) return null;
    final id = (data['id'] as String?) ?? '';
    final notification = AppNotification(
      id: id,
      type: type,
      title: (data['title'] as String?) ?? '',
      body: data['body'] as String?,
      targetRoute: (data['target_route'] as String?) ?? '/notifications',
      createdAt: DateTime.now(),
    );
    return PushMessage(
      id: id.hashCode & 0x7fffffff,
      title: notification.title,
      body: notification.body,
      route: notificationRoute(notification),
    );
  }

  /// Shows [data] unless [decide] skips it. Asks for the notification
  /// permission (Android 13+, iOS) the first time. True when shown.
  Future<bool> handle(Map<String, dynamic> data) async {
    final message = decide(data);
    if (message == null) return false;
    final request = requestPermission;
    if (!_asked && request != null) {
      _asked = true;
      try {
        _denied = await request() == false;
      } catch (_) {
        _denied = false;
      }
    }
    if (_denied) return false;
    try {
      await show(message);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// The `flutter_local_notifications` plugin, set up once from `main.dart`.
/// Until [init] succeeds (web, tests) [show] does nothing.
class LocalPushPlatform {
  LocalPushPlatform._();

  static final instance = LocalPushPlatform._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  void Function(String route)? _onTap;
  String? _pendingRoute;

  bool get isReady => _ready;

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _tapped(r.payload),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              pushChannelId,
              pushChannelName,
              description: pushChannelDescription,
              importance: Importance.high,
            ),
          );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _tapped(launch?.notificationResponse?.payload);
      }
      _ready = true;
    } catch (_) {
      _ready = false; // no plugin on this platform: stay a no-op
    }
  }

  void _tapped(String? route) {
    if (route == null || route.isEmpty) return;
    final handler = _onTap;
    if (handler == null) {
      _pendingRoute = route; // the app launched from the tap
    } else {
      handler(route);
    }
  }

  /// Where taps go (the router). A tap that launched the app is replayed.
  void onTap(void Function(String route) handler) {
    _onTap = handler;
    final pending = _pendingRoute;
    _pendingRoute = null;
    if (pending != null) handler(pending);
  }

  Future<bool?> requestPermission() async {
    if (!_ready) return null;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) return android.requestNotificationsPermission();
    return _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> show(PushMessage message) async {
    if (!_ready) return;
    await _plugin.show(
      id: message.id,
      title: message.title,
      body: message.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          pushChannelId,
          pushChannelName,
          channelDescription: pushChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.route,
    );
  }
}
