import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/app_notification.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

/// Drives the unread dot on the hub bell.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return items.where((n) => !n.isRead).length;
});
