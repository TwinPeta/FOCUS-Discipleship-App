import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/community/presentation/providers/membership_provider.dart';
import '../../features/messaging/presentation/providers/messaging_providers.dart';
import '../../features/notifications/presentation/notification_providers.dart';
import '../providers/repository_providers.dart';
import '../push/firebase_push.dart';
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
    // A phone notification from Firebase will arrive by itself while the app is
    // in the background; showing the live-socket copy as well would double it.
    remoteWillDeliver: () {
      if (ref.read(deviceRegistrationProvider)?.deviceId == null) return false;
      final state = WidgetsBinding.instance.lifecycleState;
      return state != null && state != AppLifecycleState.resumed;
    },
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
    case 'presence.updated':
      final id = event.data['community_id'];
      final count = event.data['online_count'];
      if (id is String && count is int) {
        final counts = ref.read(liveOnlineCountsProvider.notifier);
        counts.state = {...counts.state, id: count};
      }
  }
}

/// Firebase push: re-registers the device when its token changes, and opens
/// the right screen when a push is tapped (app in the background or closed).
/// Does nothing without Firebase.
final firebasePushBindingsProvider = Provider<void>((ref) {
  if (!FirebasePush.isReady) return;
  void open(RemoteMessage message) =>
      ref.read(routerProvider).go(routeForPush(message.data));
  final subs = <StreamSubscription<Object?>>[
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => unawaited(ref.read(deviceRegistrationProvider)?.refresh()),
    ),
    FirebaseMessaging.onMessageOpenedApp.listen(open),
  ];
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) open(message);
  }).ignore();
  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });
});

/// Listens to the realtime socket and keeps the device registered. Watched
/// once from `FcuApp` so it lives as long as the app.
final realtimeBindingsProvider = Provider<void>((ref) {
  ref.watch(deviceRegistrationProvider);
  ref.watch(firebasePushBindingsProvider);
  final sub = ref
      .watch(realtimeClientProvider)
      .events
      .listen((event) => applyRealtimeEvent(ref, event));
  ref.onDispose(sub.cancel);
});
