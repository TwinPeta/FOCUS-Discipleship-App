import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/community/presentation/providers/community_providers.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../../features/messaging/presentation/providers/messaging_providers.dart';
import '../../features/notifications/presentation/notification_providers.dart';
import '../providers/repository_providers.dart';
import '../push/push_service.dart';
import '../router/app_router.dart';
import 'realtime_client.dart';

/// Live "online now" counts by community id, from `presence.updated`. No
/// screen reads it yet: the community header still shows the placeholder
/// from `estimateOnlineCount` (the shells belong to the other agent).
final liveOnlineCountsProvider = StateProvider<Map<String, int>>(
  (ref) => const {},
);

/// Shows phone notifications for `notification.created`. Taps open the
/// in-app route through the router.
final pushServiceProvider = Provider<PushService>((ref) {
  final platform = LocalPushPlatform.instance;
  platform.onTap((route) => ref.read(routerProvider).go(route));
  return PushService(
    show: platform.show,
    requestPermission: platform.requestPermission,
    isAllowed: (type) {
      final prefs = ref.read(notificationPreferencesProvider).valueOrNull;
      return prefs == null || prefs.allows(type);
    },
    isViewingNotifications: () {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != null && state != AppLifecycleState.resumed) return false;
      final uri = ref
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri;
      return uri.path == '/notifications';
    },
  );
});

/// Applies one server event to the app's providers.
void applyRealtimeEvent(Ref<Object?> ref, RealtimeEvent event) {
  switch (event.name) {
    case 'notification.created':
      ref.invalidate(notificationsProvider); // the 60 s poll stays as fallback
      // The decision's notification also means the membership changed.
      final type = event.data['type'];
      if (type == 'request_approved' || type == 'request_declined') {
        ref.invalidate(membershipProvider);
      }
      unawaited(ref.read(pushServiceProvider).handle(event.data));
    case 'message.created' || 'message.read':
      ref.invalidate(threadsProvider);
      ref.invalidate(threadByIdProvider);
      final id = event.data['conversation_id'];
      if (id is String) {
        ref.invalidate(threadMessagesProvider(id));
      } else {
        ref.invalidate(threadMessagesProvider);
      }
    case 'join_request.decided':
      ref.invalidate(membershipProvider);
      ref.invalidate(notificationsProvider);
      final id = event.data['community_id'];
      if (id is String) ref.invalidate(communityByIdProvider(id));
      ref.invalidate(specificCommunitiesProvider);
    case 'presence.updated':
      final id = event.data['community_id'];
      final count = event.data['online_count'];
      if (id is String && count is int) {
        final counts = ref.read(liveOnlineCountsProvider.notifier);
        counts.state = {...counts.state, id: count};
      }
  }
}

/// Listens to the realtime socket and keeps the device registered. Watched
/// once from `FcuApp` so it lives as long as the app.
final realtimeBindingsProvider = Provider<void>((ref) {
  ref.watch(deviceRegistrationProvider);
  final sub = ref
      .watch(realtimeClientProvider)
      .events
      .listen((event) => applyRealtimeEvent(ref, event));
  ref.onDispose(sub.cancel);
});
