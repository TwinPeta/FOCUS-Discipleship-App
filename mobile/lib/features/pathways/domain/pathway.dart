enum PathwayStatus { notStarted, inProgress, completed }

/// When a pathway opens up. Configurable per pathway: today "all of these
/// pathways completed"; more conditions (role, date…) can be added here.
class UnlockRule {
  const UnlockRule({this.requiresCompleted = const []});

  static const always = UnlockRule();

  final List<String> requiresCompleted;

  bool isSatisfied(Set<String> completedPathwayIds) =>
      requiresCompleted.every(completedPathwayIds.contains);
}

/// A pathway as seen by the user. Every progress field is *derived* from
/// the step states by the repository; nothing here is stored separately.
class Pathway {
  const Pathway({
    required this.id,
    required this.title,
    required this.stepCount,
    required this.completedSteps,
    this.unlockRule = UnlockRule.always,
    this.locked = false,
  });

  final String id;
  final String title;
  final int stepCount;
  final int completedSteps;
  final UnlockRule unlockRule;
  final bool locked;

  PathwayStatus get status {
    if (stepCount > 0 && completedSteps >= stepCount) {
      return PathwayStatus.completed;
    }
    return completedSteps == 0
        ? PathwayStatus.notStarted
        : PathwayStatus.inProgress;
  }

  /// 0-based index of the current step (== stepCount when completed).
  int get currentStepIndex => completedSteps;

  double get progress => stepCount == 0 ? 0 : completedSteps / stepCount;

  /// The first prerequisite, for "Unlocks after …" copy.
  String? get unlocksAfterPathwayId => unlockRule.requiresCompleted.isEmpty
      ? null
      : unlockRule.requiresCompleted.first;
}
