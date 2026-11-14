import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/activity_event.dart';
import '../../domain/badge.dart';

final activityEventsProvider = FutureProvider<List<ActivityEvent>>((ref) {
  return ref.watch(activityRepositoryProvider).getEvents();
});

final badgesProvider = FutureProvider<List<AppBadge>>((ref) {
  return ref.watch(activityRepositoryProvider).getBadges();
});

/// Records [event], refreshes the activity/badges providers, and returns any
/// badges newly earned so the caller can show a one-time snackbar.
Future<List<AppBadge>> recordActivity(WidgetRef ref, ActivityEvent event) async {
  final newlyEarned = await ref.read(activityRepositoryProvider).record(event);
  ref.invalidate(activityEventsProvider);
  ref.invalidate(badgesProvider);
  return newlyEarned;
}
