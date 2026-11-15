import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/messaging/data/remote_messaging_repository.dart';
import 'package:focus_1/features/notifications/data/notification_repository.dart';
import 'package:focus_1/features/notifications/data/remote_notification_repository.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';
import 'package:focus_1/features/notifications/domain/notification_preferences.dart';
import 'package:focus_1/features/notifications/presentation/notification_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Counts fetches so polling can be observed.
class _CountingRepo extends FakeNotificationRepository {
  _CountingRepo() : super(latency: Duration.zero, channels: const []);
  int fetches = 0;

  @override
  Future<List<AppNotification>> getNotifications() {
    fetches++;
    return super.getNotifications();
  }
}

AppNotification _n(NotificationType type, String route) => AppNotification(
  id: 'n1',
  type: type,
  title: 't',
  targetRoute: route,
  createdAt: DateTime(2026),
);

void main() {
  group('unread count', () {
    test('polls the repository every interval; stops on dispose', () async {
      final repo = _CountingRepo();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
          notificationPollIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 40),
          ),
        ],
      );
      container.listen(unreadNotificationCountProvider, (_, _) {});
      await container.read(notificationsProvider.future);
      expect(repo.fetches, 1);
      expect(container.read(unreadNotificationCountProvider), 0);

      await repo.add(
        type: NotificationType.announcement,
        title: 'New',
        targetRoute: '/general-feed',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(repo.fetches, greaterThanOrEqualTo(2));
      expect(container.read(unreadNotificationCountProvider), 1);

      container.dispose();
      final after = repo.fetches;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(repo.fetches, after, reason: 'timer cancelled on dispose');
    });

    test('the default interval is 60 seconds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(notificationPollIntervalProvider),
        const Duration(seconds: 60),
      );
    });

    test('muted categories are not counted; warnings always are', () async {
      final repo = _CountingRepo();
      final container = ProviderContainer(
        overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await repo.add(
        type: NotificationType.announcement,
        title: 'a',
        targetRoute: '/general-feed',
      );
      await repo.add(
        type: NotificationType.moderatorWarning,
        title: 'w',
        targetRoute: '/warning/w1',
      );
      container.listen(unreadNotificationCountProvider, (_, _) {});
      await container.read(notificationsProvider.future);
      await container.read(notificationPreferencesProvider.future);
      expect(container.read(unreadNotificationCountProvider), 2);

      await container
          .read(notificationPreferencesProvider.notifier)
          .setCategory(NotificationCategory.announcements, false);
      expect(container.read(unreadNotificationCountProvider), 1);
    });
  });

  group('read sync', () {
    late _CountingRepo repo;
    late ProviderContainer container;

    setUp(() async {
      repo = _CountingRepo();
      container = ProviderContainer(
        overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
      );
      for (final t in [
        NotificationType.announcement,
        NotificationType.prayerResponse,
      ]) {
        await repo.add(type: t, title: t.name, targetRoute: '/x');
      }
      container.listen(unreadNotificationCountProvider, (_, _) {});
      await container.read(notificationsProvider.future);
    });
    tearDown(() => container.dispose());

    test('markRead updates the server and local state', () async {
      final first = (await container.read(notificationsProvider.future)).first;
      await container.read(notificationsProvider.notifier).markRead(first.id);
      expect(container.read(unreadNotificationCountProvider), 1);
      expect((await repo.getNotifications()).where((n) => n.isRead).length, 1);
    });

    test('markAllRead clears every item locally and on the server', () async {
      await container.read(notificationsProvider.notifier).markAllRead();
      expect(container.read(unreadNotificationCountProvider), 0);
      expect((await repo.getNotifications()).every((n) => n.isRead), isTrue);
    });
  });

  group('tap routing', () {
    test('uses the server target route', () {
      expect(
        notificationRoute(_n(NotificationType.prayerResponse, '/prayer/p1')),
        '/prayer/p1',
      );
      expect(
        notificationRoute(_n(NotificationType.moderatorWarning, '/warning/w1')),
        '/warning/w1',
      );
      expect(
        notificationRoute(
          _n(NotificationType.requestApproved, '/request/approved'),
        ),
        '/request/approved',
      );
    });

    test('falls back by type when the route is missing or incomplete', () {
      expect(
        notificationRoute(
          _n(NotificationType.requestDeclined, '/notifications'),
        ),
        '/request/declined',
      );
      expect(
        notificationRoute(_n(NotificationType.moderatorWarning, '/warning/')),
        '/communities',
      );
      expect(
        notificationRoute(_n(NotificationType.announcement, '')),
        '/general-feed',
      );
    });
  });

  group('remote', () {
    final seen = <http.Request>[];
    ApiClient api(Map<String, http.Response Function(http.Request)> routes) =>
        ApiClient(
          baseUrl: 'https://api.test/v1',
          client: MockClient((r) async {
            seen.add(r);
            final route = routes['${r.method} ${r.url.path}'];
            return route == null ? _json(404, {'code': 'x'}) : route(r);
          }),
        );
    setUp(seen.clear);

    test('mark read and read-all hit the API', () async {
      final repo = RemoteNotificationRepository(
        api({
          'POST /v1/me/notifications/n1/read': (_) => _json(204, null),
          'POST /v1/me/notifications/read-all': (_) => _json(204, null),
        }),
      );
      await repo.markRead('n1');
      await repo.markAllRead();
      expect(seen.map((r) => r.url.path), [
        '/v1/me/notifications/n1/read',
        '/v1/me/notifications/read-all',
      ]);
    });

    test('a retried message reuses its Idempotency-Key', () async {
      var calls = 0;
      final repo = RemoteMessagingRepository(
        api({
          'POST /v1/conversations/t1/messages': (_) => ++calls == 1
              ? _json(400, {'code': 'bad'})
              : _json(201, {
                  'id': 'm1',
                  'sender_id': 'me-id',
                  'text': 'hi',
                  'sent_at': '2026-01-01T10:00:00Z',
                }),
        }),
        myId: () => 'me-id',
      );
      await expectLater(
        repo.sendMessage('t1', 'hi', clientId: 'temp-1'),
        throwsA(anything),
      );
      await repo.sendMessage('t1', 'hi', clientId: 'temp-1');
      final keys = seen.map((r) => r.headers['Idempotency-Key']).toList();
      expect(keys, hasLength(2));
      expect(keys.first, isNotNull);
      expect(keys.first, keys.last);
    });
  });
}
