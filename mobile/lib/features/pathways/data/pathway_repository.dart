import '../domain/pathway.dart';
import '../domain/pathway_step.dart';

/// Thrown when completing a step that is not the current one (locked steps,
/// done steps, or anything in a locked pathway).
class StepNotCurrentError implements Exception {
  const StepNotCurrentError(this.stepId);
  final String stepId;
  @override
  String toString() => 'StepNotCurrentError($stepId)';
}

class PathwayLockedError implements Exception {
  const PathwayLockedError(this.pathwayId);
  final String pathwayId;
  @override
  String toString() => 'PathwayLockedError($pathwayId)';
}

/// Result of completing a step.
class StepCompletion {
  const StepCompletion({required this.step, required this.pathwayCompleted});
  final PathwayStep step;
  final bool pathwayCompleted;
}

abstract class PathwayRepository {
  Future<List<Pathway>> getPathways();

  /// Throws [ArgumentError] for an unknown id.
  Future<List<PathwayStep>> getSteps(String pathwayId);

  /// Strictly sequential: only the current step of an unlocked pathway can
  /// be completed; anything else throws.
  Future<StepCompletion> completeStep(String pathwayId, String stepId);
}
