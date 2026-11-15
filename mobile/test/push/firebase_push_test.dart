import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/push/device_registration.dart';
import 'package:focus_1/core/push/firebase_push.dart';
import 'package:focus_1/core/push/push_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Tokens implements PushTokenSource {
  _Tokens(this.values);
  final List<String> values;
  @override
  Future<String?> token() async => values.removeAt(0);
}

void main() {
  group('FirebaseConfig', () {
    const full = FirebaseConfig(
      projectId: 'fcu-demo',
      senderId: '123456',
      androidApiKey: 'AIza-android',
      androidAppId: '1:123456:android:abc',
      iosApiKey: 'AIza-ios',
      iosAppId: '1:123456:ios:def',
      iosBundleId: 'org.focusuganda.fcu',
    );

    test('builds the right options per platform', () {
      final android = full.optionsFor(TargetPlatform.android)!;
      expect(android.appId, '1:123456:android:abc');
      expect(android.apiKey, 'AIza-android');
      expect(android.projectId, 'fcu-demo');
      expect(android.messagingSenderId, '123456');

      final ios = full.optionsFor(TargetPlatform.iOS)!;
      expect(ios.appId, '1:123456:ios:def');
      expect(ios.iosBundleId, 'org.focusuganda.fcu');
      expect(full.optionsFor(TargetPlatform.macOS), isNull);
    });

    test('is off (null) unless the build was given everything it needs', () {
      expect(const FirebaseConfig().optionsFor(TargetPlatform.android), isNull);
      const noSender = FirebaseConfig(
        projectId: 'p',
        androidApiKey: 'k',
        androidAppId: 'a',
      );
      expect(noSender.optionsFor(TargetPlatform.android), isNull);
      const androidOnly = FirebaseConfig(
        projectId: 'p',
        senderId: 's',
        androidApiKey: 'k',
        androidAppId: 'a',
      );
      expect(androidOnly.optionsFor(TargetPlatform.android), isNotNull);
      expect(androidOnly.optionsFor(TargetPlatform.iOS), isNull);
    });
  });

  group('without Firebase the app is exactly as before', () {
    test('init does nothing and the token source has no token', () async {
      expect(
        await FirebasePush.init(
          config: const FirebaseConfig(),
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
      expect(FirebasePush.isReady, isFalse);
      expect(await const FirebasePushTokenSource().token(), isNull);
    });
  });

  group('routeForPush', () {
    test('opens the same screen the in-app notification does', () {
      expect(
        routeForPush({
          'type': 'prayed_for_you',
          'target_route': '/prayer/p1',
          'notification_id': 'n1',
        }),
        '/prayer/p1',
      );
      expect(
        routeForPush({
          'type': 'announcement',
          'target_route': '/notifications',
        }),
        '/general-feed', // a generic target falls back to where that kind belongs
      );
    });

    test('an unknown or missing type falls back to the notifications list', () {
      expect(routeForPush({'type': 'something_new'}), '/notifications');
      expect(routeForPush(const {}), '/notifications');
    });
  });

  group('no double notification', () {
    PushService service({required bool remote}) => PushService(
      show: (_) async {},
      isAllowed: (_) => true,
      isViewingNotifications: () => false,
      remoteWillDeliver: () => remote,
    );
    final event = {
      'id': 'n1',
      'type': 'comment_reply',
      'title': 'Someone replied',
      'target_route': '/post/1',
    };

    test('the live-socket copy is skipped when Firebase will deliver it', () {
      expect(service(remote: true).decide(event), isNull);
    });

    test('and shown when it will not (no registration, or app in front)', () {
      expect(service(remote: false).decide(event), isNotNull);
    });
  });

  test('refresh drops the old device and registers the new token', () async {
    final seen = <String>[];
    var n = 0;
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      client: MockClient((request) async {
        seen.add('${request.method} ${request.url.path}');
        if (request.method == 'POST') {
          n++;
          return http.Response(jsonEncode({'id': 'dev$n'}), 201);
        }
        return http.Response('', 204);
      }),
    )..tokens.save(access: 'a', refresh: 'r');
    final reg = DeviceRegistration(
      api,
      source: _Tokens(['old', 'new']),
      platform: 'android',
      locale: 'en',
    );
    await reg.register();
    expect(reg.deviceId, 'dev1');
    await reg.refresh();
    expect(reg.deviceId, 'dev2');
    expect(seen, [
      'POST /v1/devices',
      'DELETE /v1/devices/dev1',
      'POST /v1/devices',
    ]);
  });
}
