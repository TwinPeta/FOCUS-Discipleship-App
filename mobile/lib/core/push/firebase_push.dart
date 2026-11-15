import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/notifications/data/remote_notification_repository.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/presentation/notification_providers.dart';
import 'device_registration.dart';

/// The Firebase project's public client identifiers, given at build time so no
/// native config file is needed:
///
///   flutter build apk \
///     --dart-define=FCM_PROJECT_ID=... --dart-define=FCM_SENDER_ID=... \
///     --dart-define=FCM_API_KEY_ANDROID=... --dart-define=FCM_APP_ID_ANDROID=... \
///     --dart-define=FCM_API_KEY_IOS=...     --dart-define=FCM_APP_ID_IOS=... \
///     --dart-define=FCM_IOS_BUNDLE_ID=...
///
/// (Firebase console > Project settings > Your apps.) These are identifiers, not
/// secrets. Without them the app simply has no remote push: phone notifications
/// stay local, exactly as before.
class FirebaseConfig {
  const FirebaseConfig({
    this.projectId = const String.fromEnvironment('FCM_PROJECT_ID'),
    this.senderId = const String.fromEnvironment('FCM_SENDER_ID'),
    this.androidApiKey = const String.fromEnvironment('FCM_API_KEY_ANDROID'),
    this.androidAppId = const String.fromEnvironment('FCM_APP_ID_ANDROID'),
    this.iosApiKey = const String.fromEnvironment('FCM_API_KEY_IOS'),
    this.iosAppId = const String.fromEnvironment('FCM_APP_ID_IOS'),
    this.iosBundleId = const String.fromEnvironment('FCM_IOS_BUNDLE_ID'),
  });

  final String projectId;
  final String senderId;
  final String androidApiKey;
  final String androidAppId;
  final String iosApiKey;
  final String iosAppId;
  final String iosBundleId;

  /// The options for [platform], or null when this build was not given them.
  FirebaseOptions? optionsFor(TargetPlatform platform) {
    if (projectId.isEmpty || senderId.isEmpty) return null;
    switch (platform) {
      case TargetPlatform.android:
        if (androidApiKey.isEmpty || androidAppId.isEmpty) return null;
        return FirebaseOptions(
          apiKey: androidApiKey,
          appId: androidAppId,
          messagingSenderId: senderId,
          projectId: projectId,
        );
      case TargetPlatform.iOS:
        if (iosApiKey.isEmpty || iosAppId.isEmpty) return null;
        return FirebaseOptions(
          apiKey: iosApiKey,
          appId: iosAppId,
          messagingSenderId: senderId,
          projectId: projectId,
          iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
        );
      default:
        return null;
    }
  }
}

/// Starts Firebase once, if this build has its identifiers. Never throws.
class FirebasePush {
  FirebasePush._();

  static bool _ready = false;

  /// True once Firebase is running; everything else in this file is a no-op before.
  static bool get isReady => _ready;

  static Future<bool> init({
    FirebaseConfig config = const FirebaseConfig(),
    TargetPlatform? platform,
  }) async {
    if (kIsWeb || _ready) return _ready;
    final options = config.optionsFor(platform ?? defaultTargetPlatform);
    if (options == null) return false;
    try {
      await Firebase.initializeApp(options: options);
      _ready = true;
    } catch (_) {
      _ready = false; // no plugin on this platform, or a bad identifier
    }
    return _ready;
  }
}

/// The device's Firebase Cloud Messaging token (null without Firebase). On
/// iPhone the token only exists once Apple has handed over its own, which can
/// take a moment after launch, so it waits a little for that.
class FirebasePushTokenSource implements PushTokenSource {
  const FirebasePushTokenSource();

  @override
  Future<String?> token() async {
    if (!FirebasePush.isReady) return null;
    try {
      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 10 && await messaging.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      // The classic registration token: it is what the server's FCM HTTP v1 sender targets. (firebase_messaging 17
      // adds a separate Installation-ID model; its send target is a different feature, so it is not used here.)
      // ignore: deprecated_member_use
      return await messaging.getToken();
    } catch (_) {
      return null;
    }
  }
}

/// Where tapping a push goes: the same screen the in-app notification opens.
/// [data] is the message's data (type, target_route, notification_id).
String routeForPush(Map<String, dynamic> data) {
  final type = RemoteNotificationRepository.typeOf(data['type'] as String?);
  if (type == null) return '/notifications';
  return notificationRoute(
    AppNotification(
      id: (data['notification_id'] as String?) ?? '',
      type: type,
      title: '',
      targetRoute: (data['target_route'] as String?) ?? '/notifications',
      createdAt: DateTime.now(),
    ),
  );
}
