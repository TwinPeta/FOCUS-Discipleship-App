import 'package:flutter/foundation.dart';

import '../config/app_info.dart';
import '../network/api_client.dart';

/// Where this device's push token comes from.
///
/// The app ships [NoPushTokenSource], so nothing is registered and phone
/// notifications are local only (shown by `PushService` from realtime
/// events while the app runs). Adding real push needs only a
/// `FirebasePushTokenSource` that returns `FirebaseMessaging.instance
/// .getToken()` (package `firebase_messaging`, plus `google-services.json` /
/// `GoogleService-Info.plist` from a Firebase project) and a sender on the
/// server that delivers to the tokens stored by `POST /devices`. Nothing else
/// in [DeviceRegistration] changes.
abstract class PushTokenSource {
  /// Null when this device has no push token.
  Future<String?> token();
}

class NoPushTokenSource implements PushTokenSource {
  const NoPushTokenSource();

  @override
  Future<String?> token() async => null;
}

/// Registers the push token with the API while signed in: `POST /devices`
/// keeps the returned id, and `DELETE /devices/{id}` drops it on sign-out.
/// Never throws: push is best effort.
class DeviceRegistration {
  DeviceRegistration(
    this._api, {
    this.source = const NoPushTokenSource(),
    String? platform,
    String? locale,
  }) : platform = platform ?? _platformName(),
       locale = locale ?? PlatformDispatcher.instance.locale.toLanguageTag();

  final ApiClient _api;
  final PushTokenSource source;
  final String platform;
  final String locale;

  String? _deviceId;
  Future<void>? _registering;

  /// The id from `POST /devices`, while registered.
  String? get deviceId => _deviceId;

  static String _platformName() =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> register() =>
      _registering ??= _register().whenComplete(() => _registering = null);

  Future<void> _register() async {
    if (_deviceId != null) return;
    try {
      final token = await source.token();
      if (token == null || token.isEmpty) return;
      final json = await _api.post(
        '/devices',
        body: {
          'platform': platform,
          'push_token': token,
          // Empty in local builds (no version): left out.
          if (appVersion.isNotEmpty) 'app_version': appVersion,
          'locale': locale,
        },
      );
      final id = objectOf(json)?['id'];
      if (id is String) _deviceId = id;
    } catch (_) {
      // Offline or refused: try again on the next sign-in.
    }
  }

  /// The token changed (Firebase rotated it): drop the old registration and make a new one.
  Future<void> refresh() async {
    await unregister();
    await register();
  }

  /// Call before the tokens are cleared, so the DELETE is still signed.
  Future<void> unregister() async {
    await _registering;
    final id = _deviceId;
    if (id == null) return;
    _deviceId = null;
    try {
      await _api.delete('/devices/$id');
    } catch (_) {
      // Already gone or offline: best effort.
    }
  }
}
