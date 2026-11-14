import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/offline_cache.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../activity/domain/activity_event.dart';
import '../../../activity/domain/badge.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../../messaging/presentation/providers/moderation_providers.dart';
import '../../domain/prayer_request.dart';

class PrayerRequestsController
    extends FamilyAsyncNotifier<List<PrayerRequest>, String> {
  @override
  Future<List<PrayerRequest>> build(String communityId) async {
    final blocked = await ref.watch(blockedUserIdsProvider.future);
    final repo = ref.watch(prayerRepositoryProvider);
    // Offline: the last loaded wall (screen 56).
    final requests = await loadWithOfflineCache(
      ref,
      'prayer:$communityId',
      () => repo.getRequests(communityId),
    );
    return requests
        .where((r) => r.authorId == null || !blocked.contains(r.authorId))
        .toList();
  }

  /// Optimistic insert (deduped by id); removed again and rethrown on
  /// failure.
  Future<void> createRequest(PrayerRequest request) async {
    final current = state.valueOrNull ?? const <PrayerRequest>[];
    state = AsyncValue.data([
      request,
      ...current.where((r) => r.id != request.id),
    ]);
    try {
      await ref.read(prayerRepositoryProvider).createRequest(request);
    } catch (_) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const <PrayerRequest>[])
            .where((r) => r.id != request.id)
            .toList(),
      );
      rethrow;
    }
  }

  void _replace(String id, PrayerRequest Function(PrayerRequest) update) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final r in current) r.id == id ? update(r) : r,
    ]);
  }

  /// Toggles "I prayed" optimistically and rolls back on failure. Activity
  /// is recorded once per request (the first time it is marked), so
  /// un-marking and re-marking can never farm the Prayer partner badge.
  /// Returns any badges newly earned.
  Future<List<AppBadge>> togglePrayed(String requestId) async {
    final before = state.valueOrNull
        ?.where((r) => r.id == requestId)
        .firstOrNull;
    if (before == null) return const [];
    final prayed = !before.prayedByMe;
    _replace(
      requestId,
      (r) => r.copyWith(
        prayedByMe: prayed,
        prayedCount: r.prayedCount + (prayed ? 1 : -1),
      ),
    );

    try {
      final saved = await ref
          .read(prayerRepositoryProvider)
          .setPrayed(requestId, prayed: prayed);
      _replace(requestId, (_) => saved);
    } catch (_) {
      _replace(requestId, (_) => before);
      rethrow;
    }

    if (!prayed) return const [];
    return ref
        .read(activityRecorderProvider)
        .record(
          ActivityType.prayed,
          'Prayed for a request',
          sourceId: requestId,
        );
  }
}

final prayerRequestsProvider =
    AsyncNotifierProvider.family<
      PrayerRequestsController,
      List<PrayerRequest>,
      String
    >(PrayerRequestsController.new);
