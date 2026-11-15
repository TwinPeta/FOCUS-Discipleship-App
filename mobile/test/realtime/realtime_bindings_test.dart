import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/push/push_service.dart';
import 'package:focus_1/core/realtime/realtime_bindings.dart';
import 'package:focus_1/core/realtime/realtime_client.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:focus_1/features/notifications/presentation/notification_providers.dart';

import '../support/fake_backend.dart';
import '../support/fakes.dart';

class _ScriptedClient implements RealtimeClient {
  final controller = StreamController<RealtimeEvent>.broadcast();

  @override
  Stream<RealtimeEvent> get events => controller.stream;

  @override
  void start() {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() => controller.close();
}

class _CountingNotifications extends FakeNotificationRepository {
  _CountingNotifications() : super(latency: Duration.zero);

  int fetches = 0;

  @override
  Future<List<AppNotification>> getNotifications() {
    fetches++;
    return super.getNotifications();
  }
}

RealtimeEvent _event(String name, Map<String, dynamic> data) =>
    RealtimeEvent(name, data, DateTime(2026, 11, 15));

void main() {
  late _ScriptedClient socket;
  late _CountingNotifications notifications;
  late List<Map<String, dynamic>> pushed;
  late ProviderContainer container;

  setUp(() {
    socket = _ScriptedClient();
    notifications = _CountingNotifications();
    pushed = [];
    container = fakeContainer(
      overrides: [
        realtimeClientProvider.overrideWithValue(socket),
        notificationRepositoryProvider.overrideWith((ref) => notifications),
        pushServiceProvider.overrideWithValue(
          PushService(
            show: (m) async => pushed.add({'title': m.title, 'route': m.route}),
            isAllowed: (_) => true,
            isViewingNotifications: () => false,
          ),
        ),
      ],
    );
    container.read(realtimeBindingsProvider);
  });

  tearDown(() {
    socket.dispose();
    container.dispose();
  });

  test('the API is off under the fakes: no-op client, no registration', () {
    final plain = fakeContainer();
    addTearDown(plain.dispose);
    expect(plain.read(realtimeClientProvider), isA<NoopRealtimeClient>());
    expect(plain.read(deviceRegistrationProvider), isNull);
  });

  test('notification.created re-fetches the notifications', () async {
    container.listen(notificationsProvider, (_, _) {});
    await container.read(notificationsProvider.future);
    expect(notifications.fetches, 1);

    socket.controller.add(
      _event('notification.created', {
        'id': 'n1',
        'type': 'announcement',
        'title': 'Hello',
        'target_route': '/general-feed',
      }),
    );
    await pumpEventQueue();
    await container.read(notificationsProvider.future);
    expect(notifications.fetches, 2);
    expect(pushed, [
      {'title': 'Hello', 'route': '/general-feed'},
    ]);
  });

  test('join_request.decided refreshes the membership', () async {
    var refreshes = 0;
    container.listen(membershipProvider, (_, next) {
      if (next.isRefreshing) refreshes++;
    });
    await container.read(membershipProvider.future);
    socket.controller.add(
      _event('join_request.decided', {'community_id': 'c1', 'status': 'x'}),
    );
    await pumpEventQueue();
    expect(refreshes, 1);
  });

  test('a decision notification also refreshes the membership', () async {
    var refreshes = 0;
    container.listen(membershipProvider, (_, next) {
      if (next.isRefreshing) refreshes++;
    });
    await container.read(membershipProvider.future);
    socket.controller.add(
      _event('notification.created', {
        'id': 'n1',
        'type': 'request_declined',
        'title': 'Your request was not accepted',
        'target_route': '/request/declined',
      }),
    );
    await pumpEventQueue();
    expect(refreshes, 1);

    socket.controller.add(
      _event('notification.created', {
        'id': 'n2',
        'type': 'comment_reply',
        'title': 'Someone replied',
        'target_route': '/post/p1',
      }),
    );
    await pumpEventQueue();
    expect(refreshes, 1, reason: 'other notifications leave it alone');
  });

  test('presence.updated stores the live online count', () async {
    socket.controller.add(
      _event('presence.updated', {'community_id': 'c1', 'online_count': 7}),
    );
    await pumpEventQueue();
    expect(container.read(liveOnlineCountsProvider), {'c1': 7});
  });
}
