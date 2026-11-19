import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/config/app_info.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/push/device_registration.dart';
import 'package:focus_1/core/push/push_service.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TokenSource implements PushTokenSource {
  _TokenSource(this.value);

  final String? value;

  @override
  Future<String?> token() async => value;
}

Map<String, dynamic> _created(String type, {String route = '/prayer/p1'}) => {
  'id': 'n1',
  'type': type,
  'title': 'Someone prayed for you',
  'body': 'Grace prayed for your request',
  'target_route': route,
  'read_at': null,
  'created_at': '2026-11-15T10:00:00.000Z',
};

void main() {
  group('DeviceRegistration', () {
    late List<http.Request> seen;
    late ApiClient api;

    setUp(() {
      seen = [];
      api = ApiClient(
        baseUrl: 'https://api.test/v1',
        client: MockClient((request) async {
          seen.add(request);
          if (request.method == 'POST') {
            return http.Response(jsonEncode({'id': 'dev1'}), 201);
          }
          return http.Response('', 204);
        }),
      )..tokens.save(access: 'a', refresh: 'r');
    });

    test('posts the token, keeps the id, deletes it on sign-out', () async {
      final reg = DeviceRegistration(
        api,
        source: _TokenSource('tok'),
        platform: 'android',
        locale: 'en-UG',
      );
      await reg.register();
      await reg.register(); // already registered: no second POST

      expect(seen, hasLength(1));
      expect(seen.single.url.path, '/v1/devices');
      expect(jsonDecode(seen.single.body), {
        'platform': 'android',
        'push_token': 'tok',
        if (appVersion.isNotEmpty) 'app_version': appVersion,
        'locale': 'en-UG',
      });
      expect(seen.single.headers['Authorization'], 'Bearer a');
      expect(reg.deviceId, 'dev1');

      await reg.unregister();
      expect(seen.last.method, 'DELETE');
      expect(seen.last.url.path, '/v1/devices/dev1');
      expect(reg.deviceId, isNull);
    });

    test('NoPushTokenSource registers nothing', () async {
      final reg = DeviceRegistration(api, platform: 'android', locale: 'en');
      await reg.register();
      await reg.unregister();
      expect(seen, isEmpty);
    });
  });

  group('PushService', () {
    late List<PushMessage> shown;
    late bool muted;
    late bool viewing;
    late int asks;
    late bool? grant;
    late PushService push;

    setUp(() {
      shown = [];
      muted = false;
      viewing = false;
      asks = 0;
      grant = true;
      push = PushService(
        show: (m) async => shown.add(m),
        isAllowed: (type) => !(muted && type == NotificationType.prayedForYou),
        isViewingNotifications: () => viewing,
        requestPermission: () async {
          asks++;
          return grant;
        },
      );
    });

    test('shows title, body and the in-app route', () async {
      expect(await push.handle(_created('prayed_for_you')), isTrue);
      expect(shown.single.title, 'Someone prayed for you');
      expect(shown.single.body, 'Grace prayed for your request');
      expect(shown.single.route, '/prayer/p1');
      await push.handle(_created('prayed_for_you'));
      expect(asks, 1); // permission asked only the first time
    });

    test('falls back to the type route when target_route is incomplete', () {
      final m = push.decide(_created('request_approved', route: '/'));
      expect(m?.route, '/request/approved');
    });

    test('skips muted categories, unknown types and the open screen', () async {
      muted = true;
      expect(await push.handle(_created('prayed_for_you')), isFalse);
      expect(await push.handle(_created('something_new')), isFalse);
      muted = false;
      viewing = true;
      expect(await push.handle(_created('prayed_for_you')), isFalse);
      expect(shown, isEmpty);
    });

    test('a denied permission shows nothing', () async {
      grant = false;
      expect(await push.handle(_created('announcement')), isFalse);
      expect(shown, isEmpty);
    });
  });
}
