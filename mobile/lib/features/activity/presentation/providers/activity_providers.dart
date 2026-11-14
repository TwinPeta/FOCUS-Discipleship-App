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

/// The one place activity is recorded. Called by the controllers that own
/// each action (prayer, pathways, resources, testimonies), never by widgets.
class ActivityRecorder {
  ActivityRecorder(this._ref);

  final Ref _ref;

  /// Records the event, refreshes My activity, and returns badges newly
  /// earned (for a one-time snackbar). With [sourceId], repeats of the same
  /// type and source are ignored.
  Future<List<AppBadge>> record(
    ActivityType type,
    String label, {
    String? sourceId,
  }) async {
    final earned = await _ref
        .read(activityRepositoryProvider)
        .record(
          ActivityEvent(
            type: type,
            label: label,
            at: DateTime.now(),
            sourceId: sourceId,
          ),
        );
    _ref.invalidate(activityEventsProvider);
    _ref.invalidate(badgesProvider);
    return earned;
  }
}

final activityRecorderProvider = Provider<ActivityRecorder>(
  ActivityRecorder.new,
);
