enum PathwayStatus { notStarted, inProgress, completed }

class Pathway {
  const Pathway({
    required this.id,
    required this.title,
    required this.stepCount,
    this.unlocksAfterPathwayId,
    required this.status,
    this.currentStepIndex = 0,
  });

  final String id;
  final String title;
  final int stepCount;

  /// Non-null for pathways that stay locked until this other pathway is
  /// completed (pathways 1 and 2 have no prerequisite).
  final String? unlocksAfterPathwayId;
  final PathwayStatus status;

  /// 0-based index of the current/next step, for "Step N of stepCount".
  final int currentStepIndex;

  Pathway copyWith({PathwayStatus? status, int? currentStepIndex}) {
    return Pathway(
      id: id,
      title: title,
      stepCount: stepCount,
      unlocksAfterPathwayId: unlocksAfterPathwayId,
      status: status ?? this.status,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    );
  }
}
