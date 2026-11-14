import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/app_notification.dart';
import '../domain/notification_preferences.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

/// Drives the unread dot on the hub bell.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return items.where((n) => !n.isRead).length;
});

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
