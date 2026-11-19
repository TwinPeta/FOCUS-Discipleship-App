import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/realtime/realtime_bindings.dart';
import '../domain/app_notification.dart';
import '../domain/notification_preferences.dart';

/// How often the list (and so the bell's unread dot) is re-fetched while
/// the app runs. Overridable in tests.
final notificationPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);

/// The signed-in user's notifications, newest first. Loaded once and updated
/// by the live socket; while the socket is down it re-fetches itself every
/// [notificationPollIntervalProvider] (the hub bell keeps it alive). The timer
/// is cancelled whenever the state is rebuilt or disposed. Reads are applied locally right away and synced to the server.
class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() {
    // Loaded once; the socket pushes new ones. Only while it is down does the
    // list check again on a timer, so nothing is missed.
    if (!ref.watch(realtimeConnectedProvider)) {
      final timer = Timer(
        ref.watch(notificationPollIntervalProvider),
        ref.invalidateSelf,
      );
      ref.onDispose(timer.cancel);
    }
    return ref.watch(notificationRepositoryProvider).getNotifications();
  }

  void _setRead(bool Function(AppNotification) test) {
    final items = state.valueOrNull;
    if (items == null) return;
    final now = DateTime.now();
    state = AsyncData([
      for (final n in items)
        if (!n.isRead && test(n)) n.copyWith(readAt: now) else n,
    ]);
  }

  /// Marks [id] read on the server, then locally. Throws on failure, leaving
  /// the local state as it was.
  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markRead(id);
    _setRead((n) => n.id == id);
  }

  /// `POST /me/notifications/read-all`, then marks every local item read.
  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    _setRead((_) => true);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

/// Drives the unread dot on the hub bell. Types whose category the member
/// muted are not counted (moderator warnings always are).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
  return items
      .where((n) => !n.isRead && (prefs == null || prefs.allows(n.type)))
      .length;
});

/// Where tapping [n] goes. The server sends the app route (`target_route`,
/// e.g. `/prayer/{id}`, `/warning/{id}`, `/request/approved`); when it is
/// missing or incomplete, fall back by type.
String notificationRoute(AppNotification n) {
  final target = n.targetRoute.trim();
  final incomplete = target.isEmpty || target.endsWith('/');
  if (!incomplete && target != '/notifications') return target;
  return switch (n.type) {
    NotificationType.requestApproved => '/request/approved',
    NotificationType.requestDeclined => '/request/declined',
    NotificationType.announcement => '/general-feed',
    NotificationType.moderatorWarning ||
    NotificationType.commentReply ||
    NotificationType.prayedForYou ||
    NotificationType.prayerResponse ||
    NotificationType.meetingReminder ||
    NotificationType.inactivity => '/communities',
  };
}

/// The signed-in user's notification settings (screen 45). Each change is
/// saved right away; a failed save restores the previous value and rethrows.
class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() =>
      ref.watch(notificationRepositoryProvider).getPreferences();

  Future<void> _save(NotificationPreferences next) async {
    final previous = state.valueOrNull;
    state = AsyncData(next);
    try {
      state = AsyncData(
        await ref.read(notificationRepositoryProvider).savePreferences(next),
      );
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> setCategory(NotificationCategory c, bool on) async {
    final current = state.valueOrNull;
    if (current != null) await _save(current.withCategory(c, on));
  }

  Future<void> setChannel(DeliveryChannel c, bool on) async {
    final current = state.valueOrNull;
    if (current != null) await _save(current.withChannel(c, on));
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<
      NotificationPreferencesController,
      NotificationPreferences
    >(NotificationPreferencesController.new);
