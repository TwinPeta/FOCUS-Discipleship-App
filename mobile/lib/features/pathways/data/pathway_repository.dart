import '../domain/pathway.dart';
import '../domain/pathway_step.dart';

abstract class PathwayRepository {
  Future<List<Pathway>> getPathways();
  Future<List<PathwayStep>> getSteps(String pathwayId);

  /// Marks [stepId] done, unlocks the next step (or marks the pathway
  /// completed if it was the last one). Returns the updated step.
  Future<PathwayStep> completeStep(String pathwayId, String stepId);
}

class FakePathwayRepository implements PathwayRepository {
  static const _latency = Duration(milliseconds: 400);

  late final List<Pathway> _pathways = [
    const Pathway(
      id: 'pathway-1',
      title: 'Foundations of faith',
      stepCount: 4,
      status: PathwayStatus.inProgress,
      currentStepIndex: 2,
    ),
    const Pathway(
      id: 'pathway-2',
      title: 'Growing as a disciple',
      stepCount: 3,
      status: PathwayStatus.notStarted,
    ),
    const Pathway(
      id: 'pathway-3',
      title: 'Leading your first group',
      stepCount: 3,
      unlocksAfterPathwayId: 'pathway-1',
      status: PathwayStatus.notStarted,
    ),
    const Pathway(
      id: 'pathway-4',
      title: 'Serving your campus',
      stepCount: 3,
      unlocksAfterPathwayId: 'pathway-1',
      status: PathwayStatus.notStarted,
    ),
  ];

  late final Map<String, List<PathwayStep>> _steps = {
    'pathway-1': [
      const PathwayStep(
        id: 'pathway-1-step-1',
        pathwayId: 'pathway-1',
        index: 0,
        type: PathwayStepType.video,
        title: 'Why discipleship matters',
        meta: '6 min video',
        status: PathwayStepStatus.done,
      ),
      const PathwayStep(
        id: 'pathway-1-step-2',
        pathwayId: 'pathway-1',
        index: 1,
        type: PathwayStepType.devotional,
        title: 'Rooted in Christ',
        meta: '5 min devotional',
        status: PathwayStepStatus.done,
      ),
      const PathwayStep(
        id: 'pathway-1-step-3',
        pathwayId: 'pathway-1',
        index: 2,
        type: PathwayStepType.quiz,
        title: 'Quiz: the basics of faith',
        meta: '6 questions',
        status: PathwayStepStatus.current,
      ),
      const PathwayStep(
        id: 'pathway-1-step-4',
        pathwayId: 'pathway-1',
        index: 3,
        type: PathwayStepType.video,
        title: 'Living it out daily',
        meta: '7 min video',
        status: PathwayStepStatus.locked,
      ),
    ],
    'pathway-2': [
      const PathwayStep(
        id: 'pathway-2-step-1',
        pathwayId: 'pathway-2',
        index: 0,
        type: PathwayStepType.devotional,
        title: 'What does growth look like?',
        meta: '5 min devotional',
        status: PathwayStepStatus.current,
      ),
      const PathwayStep(
        id: 'pathway-2-step-2',
        pathwayId: 'pathway-2',
        index: 1,
        type: PathwayStepType.video,
        title: 'Habits of a disciple',
        meta: '8 min video',
        status: PathwayStepStatus.locked,
      ),
      const PathwayStep(
        id: 'pathway-2-step-3',
        pathwayId: 'pathway-2',
        index: 2,
        type: PathwayStepType.quiz,
        title: 'Quiz: spiritual habits',
        meta: '5 questions',
        status: PathwayStepStatus.locked,
      ),
    ],
    'pathway-3': [
      const PathwayStep(
        id: 'pathway-3-step-1',
        pathwayId: 'pathway-3',
        index: 0,
        type: PathwayStepType.video,
        title: 'What makes a good leader',
        meta: '7 min video',
        status: PathwayStepStatus.current,
      ),
      const PathwayStep(
        id: 'pathway-3-step-2',
        pathwayId: 'pathway-3',
        index: 1,
        type: PathwayStepType.devotional,
        title: 'Serving before leading',
        meta: '5 min devotional',
        status: PathwayStepStatus.locked,
      ),
      const PathwayStep(
        id: 'pathway-3-step-3',
        pathwayId: 'pathway-3',
        index: 2,
        type: PathwayStepType.quiz,
        title: 'Quiz: leading your first group',
        meta: '6 questions',
        status: PathwayStepStatus.locked,
      ),
    ],
    'pathway-4': [
      const PathwayStep(
        id: 'pathway-4-step-1',
        pathwayId: 'pathway-4',
        index: 0,
        type: PathwayStepType.devotional,
        title: 'A heart to serve',
        meta: '5 min devotional',
        status: PathwayStepStatus.current,
      ),
      const PathwayStep(
        id: 'pathway-4-step-2',
        pathwayId: 'pathway-4',
        index: 1,
        type: PathwayStepType.video,
        title: 'Finding where you fit',
        meta: '6 min video',
        status: PathwayStepStatus.locked,
      ),
      const PathwayStep(
        id: 'pathway-4-step-3',
        pathwayId: 'pathway-4',
        index: 2,
        type: PathwayStepType.quiz,
        title: 'Quiz: serving your campus',
        meta: '5 questions',
        status: PathwayStepStatus.locked,
      ),
    ],
  };

  @override
  Future<List<Pathway>> getPathways() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_pathways);
  }

  @override
  Future<List<PathwayStep>> getSteps(String pathwayId) async {
    await Future.delayed(_latency);
    return List.unmodifiable(_steps[pathwayId] ?? const []);
  }

  @override
  Future<PathwayStep> completeStep(String pathwayId, String stepId) async {
    await Future.delayed(_latency);
    final steps = _steps[pathwayId];
    if (steps == null) {
      throw ArgumentError('Unknown pathway id: $pathwayId');
    }
    final index = steps.indexWhere((s) => s.id == stepId);
    if (index == -1) {
      throw ArgumentError('Unknown step id: $stepId');
    }

    final completed = steps[index].copyWith(status: PathwayStepStatus.done);
    steps[index] = completed;

    final pathwayIndex = _pathways.indexWhere((p) => p.id == pathwayId);
    final isLastStep = index == steps.length - 1;

    if (!isLastStep) {
      steps[index + 1] = steps[index + 1].copyWith(status: PathwayStepStatus.current);
      _pathways[pathwayIndex] = _pathways[pathwayIndex].copyWith(
        status: PathwayStatus.inProgress,
        currentStepIndex: index + 1,
      );
    } else {
      _pathways[pathwayIndex] = _pathways[pathwayIndex].copyWith(
        status: PathwayStatus.completed,
        currentStepIndex: steps.length,
      );
    }

    return completed;
  }
}
