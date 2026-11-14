import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../activity/domain/activity_event.dart';
import '../../../activity/domain/badge.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../domain/pathway.dart';
import '../../domain/pathway_step.dart';

final pathwaysProvider = FutureProvider<List<Pathway>>((ref) {
  return ref.watch(pathwayRepositoryProvider).getPathways();
});

class PathwayStepsController
    extends FamilyAsyncNotifier<List<PathwayStep>, String> {
  bool _completing = false;

  @override
  Future<List<PathwayStep>> build(String pathwayId) {
    return ref.watch(pathwayRepositoryProvider).getSteps(pathwayId);
  }

  /// Completes the current step (the repository rejects anything else),
  /// refreshes progress and records "pathway completed" on the last step.
  /// The step's own activity (video, quiz…) is recorded by the viewer that
  /// completed it. A second call while one is in flight is ignored.
  /// Returns badges newly earned.
  Future<List<AppBadge>> completeStep(String stepId) async {
    if (_completing) return const [];
    _completing = true;
    try {
      final repo = ref.read(pathwayRepositoryProvider);
      final result = await repo.completeStep(arg, stepId);
      state = AsyncValue.data(await repo.getSteps(arg));
      ref.invalidate(pathwaysProvider);

      final recorder = ref.read(activityRecorderProvider);
      final earned = <AppBadge>[];
      if (result.pathwayCompleted) {
        earned.addAll(
          await recorder.record(
            ActivityType.pathwayCompleted,
            'Completed a pathway',
            sourceId: arg,
          ),
        );
      }
      return earned;
    } finally {
      _completing = false;
    }
  }
}

final pathwayStepsProvider =
    AsyncNotifierProvider.family<
      PathwayStepsController,
      List<PathwayStep>,
      String
    >(PathwayStepsController.new);
