import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../activity/domain/activity_event.dart';
import '../../../activity/domain/badge.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../domain/prayer_request.dart';

class PrayerRequestsController
    extends FamilyAsyncNotifier<List<PrayerRequest>, String> {
  @override
  Future<List<PrayerRequest>> build(String communityId) {
    return ref.watch(prayerRepositoryProvider).getRequests(communityId);
  }

  Future<void> createRequest(PrayerRequest request) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([request, ...current]);
    await ref.read(prayerRepositoryProvider).createRequest(request);
  }

  /// Returns any badges newly earned (only possible when marking "I
  /// prayed", not when un-marking it).
  Future<List<AppBadge>> togglePrayed(String requestId) async {
    final current = state.valueOrNull;
    if (current == null) return const [];
    final index = current.indexWhere((r) => r.id == requestId);
    if (index == -1) return const [];

    final willBePrayed = !current[index].prayedByMe;
    final toggled = current[index].copyWith(
      prayedByMe: willBePrayed,
      prayedCount: willBePrayed
          ? current[index].prayedCount + 1
          : current[index].prayedCount - 1,
    );
    final optimistic = [...current];
    optimistic[index] = toggled;
    state = AsyncValue.data(optimistic);

    await ref.read(prayerRepositoryProvider).togglePrayed(requestId);

    if (!willBePrayed) return const [];
    final newlyEarned = await ref.read(activityRepositoryProvider).record(
      ActivityEvent(type: 'prayed', label: 'Prayed for a request', at: DateTime.now()),
    );
    ref.invalidate(activityEventsProvider);
    ref.invalidate(badgesProvider);
    return newlyEarned;
  }
}

final prayerRequestsProvider = AsyncNotifierProvider.family<
    PrayerRequestsController, List<PrayerRequest>, String>(
  PrayerRequestsController.new,
);
