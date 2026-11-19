import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/realtime/realtime_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A socket the test drives by hand; never touches the network.
class FakeChannel implements RealtimeChannel {
  FakeChannel(this.uri);

  final Uri uri;
  final controller = StreamController<dynamic>();
  bool closed = false;

  @override
  int? closeCode;

  @override
  Future<void> get ready async {}

  @override
  Stream<dynamic> get stream => controller.stream;

  void serverClose([int? code]) {
    closeCode = code;
    controller.close();
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!controller.isClosed) await controller.close();
  }
}

String frame(String event, Map<String, dynamic> data) => jsonEncode({
  'event': event,
  'data': data,
  'at': '2026-11-15T10:00:00.000Z',
});

void main() {
  group('realtimeUri', () {
    test('https becomes wss and http becomes ws, under the /v1 base', () {
      expect(
        realtimeUri('https://apis.focusuganda.org/v1', 'abc').toString(),
        'wss://apis.focusuganda.org/v1/realtime?token=abc',
      );
      expect(
        realtimeUri('http://10.0.2.2:4000/v1/', 'a b').toString(),
        'ws://10.0.2.2:4000/v1/realtime?token=a+b',
      );
    });
  });

  group('SocketRealtimeClient', () {
    late List<FakeChannel> channels;
    late List<Duration> waits;
    late List<Completer<void>> delays;
    late int refreshCalls;
    late int refreshStatus;
    late ApiClient api;
    late SocketRealtimeClient client;

    setUp(() {
      channels = [];
      waits = [];
      delays = [];
      refreshCalls = 0;
      refreshStatus = 200;
      api = ApiClient(
        baseUrl: 'https://api.test/v1',
        client: MockClient((request) async {
          if (request.url.path == '/v1/auth/refresh') {
            refreshCalls++;
            return http.Response(
              jsonEncode({'access_token': 'new', 'refresh_token': 'r2'}),
              refreshStatus,
            );
          }
          return http.Response('', 404);
        }),
      )..tokens.save(access: 'old', refresh: 'r1');
      client = SocketRealtimeClient(
        api: api,
        connect: (uri) {
          final c = FakeChannel(uri);
          channels.add(c);
          return c;
        },
        delay: (wait) {
          waits.add(wait);
          final c = Completer<void>();
          delays.add(c);
          return c.future;
        },
      );
    });

    tearDown(() => client.dispose());

    test('connects with the access token and parses frames', () async {
      final events = <RealtimeEvent>[];
      client.events.listen(events.add);
      client.start();
      expect(channels.single.uri.queryParameters['token'], 'old');
      expect(channels.single.uri.scheme, 'wss');

      channels.single.controller
        ..add(frame('message.read', {'conversation_id': 'c1'}))
        ..add('not json')
        ..add(jsonEncode({'data': {}}));
      await pumpEventQueue();

      expect(events, hasLength(1));
      expect(events.single.name, 'message.read');
      expect(events.single.data['conversation_id'], 'c1');
      expect(events.single.at, DateTime.utc(2026, 11, 15, 10));
    });

    test('reconnects after a close with 1, 2, 5 s backoff', () async {
      client.start();
      channels.last.serverClose(1006);
      await pumpEventQueue();
      expect(waits, [const Duration(seconds: 1)]);
      expect(channels, hasLength(1));

      delays.last.complete();
      await pumpEventQueue();
      expect(channels, hasLength(2));

      channels.last.serverClose(1006);
      await pumpEventQueue();
      delays.last.complete();
      await pumpEventQueue();
      channels.last.serverClose(1006);
      await pumpEventQueue();
      expect(waits, const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 5),
      ]);
    });

    test('a 4401 close refreshes the token once, then reconnects', () async {
      client.start();
      channels.last.serverClose(realtimeUnauthorizedCode);
      await pumpEventQueue();

      expect(refreshCalls, 1);
      expect(waits, isEmpty);
      expect(channels, hasLength(2));
      expect(channels.last.uri.queryParameters['token'], 'new');

      // A second 4401 in a row stops instead of looping.
      channels.last.serverClose(realtimeUnauthorizedCode);
      await pumpEventQueue();
      expect(refreshCalls, 1);
      expect(client.isRunning, isFalse);
    });

    test('stop closes the socket and does not reconnect', () async {
      client.start();
      final first = channels.single;
      await client.stop();
      expect(first.closed, isTrue);
      await pumpEventQueue();
      expect(channels, hasLength(1));
      expect(waits, isEmpty);
    });

    test('does not connect without a token', () {
      api.tokens.clear();
      client.start();
      expect(channels, isEmpty);
      expect(client.isRunning, isFalse);
    });
  });
}
