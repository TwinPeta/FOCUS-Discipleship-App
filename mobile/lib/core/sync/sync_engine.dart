import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/activity/presentation/providers/activity_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/community/presentation/providers/membership_provider.dart';
import '../../features/feed/presentation/providers/feed_providers.dart';
import '../../features/feed/presentation/providers/post_detail_providers.dart';
import '../../features/meetings/presentation/meeting_providers.dart';
import '../../features/messaging/presentation/providers/messaging_providers.dart';
import '../../features/notifications/presentation/notification_providers.dart';
import '../../features/pathways/presentation/providers/pathway_providers.dart';
import '../../features/prayer/presentation/providers/prayer_detail_providers.dart';
import '../../features/prayer/presentation/providers/prayer_providers.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/resources/presentation/providers/resource_providers.dart';
import '../../features/testimony/presentation/providers/testimony_detail_providers.dart';
import '../../features/testimony/presentation/providers/testimony_providers.dart';
import '../connectivity/connectivity_service.dart';
import '../providers/repository_providers.dart';

/// Sends the outbox (writes made offline) when the app is back online, when
/// it returns to the foreground, after signing in and whenever a write is
/// queued while online. Afterwards the screens reload, so they show the
/// server's own ids, times and counts. Watched by the app root; does
/// nothing in tests (no live API).
class SyncEngine {
  SyncEngine(this._ref) {
    final net = _ref.read(connectivityServiceProvider);
    final outbox = _ref.read(outboxProvider);
    _subs
      ..add(
        net.onlineChanges.listen((online) {
          if (online) unawaited(run(refreshScreens: true));
        }),
      )
      ..add(
        outbox.changes.listen((_) {
          if (net.isOnline && !_running) unawaited(run());
        }),
      );
    try {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          if (net.isOnline) unawaited(run());
        },
      );
    } catch (_) {
      _lifecycle = null; // no binding
    }
    _ref.listen(authSessionProvider, (before, now) {
      if (now != null && before?.accountId != now.accountId) {
        unawaited(run());
      }
    });
    unawaited(run());
    // Old saved replies are dropped now and then.
    unawaited(_ref.read(localDatabaseProvider).prune().catchError((_) {}));
  }

  final Ref _ref;
  final List<StreamSubscription<void>> _subs = [];
  AppLifecycleListener? _lifecycle;
  bool _running = false;
  bool _disposed = false;

  /// Sends what is waiting; [refreshScreens] reloads them even when
  /// nothing was sent (back online: saved copies are replaced by fresh
  /// ones).
  Future<void> run({bool refreshScreens = false}) async {
    if (_disposed) return;
    if (_ref.read(authSessionProvider) == null) return;
    _running = true;
    try {
      final result = await _ref.read(outboxProvider).drain();
      if (_disposed) return;
      if (refreshScreens || result.sent > 0 || result.failed > 0) {
        _refresh();
      }
    } catch (_) {
      // Tried again on the next trigger.
    } finally {
      _running = false;
    }
  }

  void _refresh() {
    _ref
      ..invalidate(feedPostsProvider)
      ..invalidate(postDetailProvider)
      ..invalidate(postCommentsProvider)
      ..invalidate(prayerRequestsProvider)
      ..invalidate(prayerRequestByIdProvider)
      ..invalidate(prayerResponsesProvider)
      ..invalidate(testimoniesProvider)
      ..invalidate(testimonyDetailProvider)
      ..invalidate(threadsProvider)
      ..invalidate(threadMessagesProvider)
      ..invalidate(notificationsProvider)
      ..invalidate(notificationPreferencesProvider)
      ..invalidate(meetingScheduleProvider)
      ..invalidate(pathwaysProvider)
      ..invalidate(resourcesProvider)
      ..invalidate(activityEventsProvider)
      ..invalidate(badgesProvider)
      ..invalidate(pendingWritesProvider);
    // These drive the router: reload them without a loading state.
    unawaited(_ref.read(profileControllerProvider.notifier).refreshQuietly());
    unawaited(_ref.read(membershipProvider.notifier).refreshQuietly());
  }

  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    _lifecycle?.dispose();
  }
}

/// The running [SyncEngine], or null when the app is not talking to the
/// real API (tests).
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  if (!ref.watch(liveApiEnabledProvider)) return null;
  final engine = SyncEngine(ref);
  ref.onDispose(engine.dispose);
  return engine;
});

/// How many offline writes are still waiting to be sent (0 in tests).
final pendingWritesProvider = StreamProvider<int>((ref) async* {
  final outbox = ref.watch(outboxProvider);
  yield await outbox.pendingCount();
  await for (final _ in outbox.changes) {
    yield await outbox.pendingCount();
  }
});
