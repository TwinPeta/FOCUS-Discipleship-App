import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../activity/domain/activity_event.dart';
import '../../../activity/domain/badge.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../domain/pathway.dart';
import '../../domain/pathway_step.dart';

class PathwaysController extends AsyncNotifier<List<Pathway>> {
  @override
  Future<List<Pathway>> build() {
    return ref.watch(pathwayRepositoryProvider).getPathways();
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await ref.read(pathwayRepositoryProvider).getPathways());
  }
}

final pathwaysProvider = AsyncNotifierProvider<PathwaysController, List<Pathway>>(
  PathwaysController.new,
);

class PathwayStepsController extends FamilyAsyncNotifier<List<PathwayStep>, String> {
  @override
  Future<List<PathwayStep>> build(String pathwayId) {
    return ref.watch(pathwayRepositoryProvider).getSteps(pathwayId);
  }

  /// Marks [stepId] done, refreshes both this pathway's steps and the
  /// pathway list (progress bar / unlock rules may have changed), and
  /// returns any badges newly earned.
  Future<List<AppBadge>> completeStep(String stepId) async {
    final before = state.valueOrNull ?? const <PathwayStep>[];
    final completedStep = before.firstWhere((s) => s.id == stepId, orElse: () => before.first);
    final isLastStep = before.isNotEmpty && completedStep.index == before.length - 1;

    await ref.read(pathwayRepositoryProvider).completeStep(arg, stepId);
    state = AsyncValue.data(await ref.read(pathwayRepositoryProvider).getSteps(arg));
    ref.invalidate(pathwaysProvider);

    final newlyEarned = <AppBadge>[];
    if (completedStep.type == PathwayStepType.quiz) {
      newlyEarned.addAll(await ref.read(activityRepositoryProvider).record(
        ActivityEvent(type: 'quiz_completed', label: 'Completed "${completedStep.title}"', at: DateTime.now()),
      ));
    }
    if (isLastStep) {
      newlyEarned.addAll(await ref.read(activityRepositoryProvider).record(
        ActivityEvent(type: 'pathway_completed', label: 'Completed a pathway', at: DateTime.now()),
      ));
    }
    if (newlyEarned.isNotEmpty) {
      ref.invalidate(activityEventsProvider);
      ref.invalidate(badgesProvider);
    }
    return newlyEarned;
  }
}

final pathwayStepsProvider = AsyncNotifierProvider.family<
    PathwayStepsController, List<PathwayStep>, String>(
  PathwayStepsController.new,
);
