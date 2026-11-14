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

class _StepDef {
  const _StepDef(this.type, this.title, this.meta);
  final PathwayStepType type;
  final String title;
  final String meta;
}

class _PathwayDef {
  const _PathwayDef(
    this.id,
    this.title,
    this.steps, [
    this.rule = UnlockRule.always,
  ]);
  final String id;
  final String title;
  final List<_StepDef> steps;
  final UnlockRule rule;

  String stepId(int index) => '$id-step-${index + 1}';
}

class FakePathwayRepository implements PathwayRepository {
  FakePathwayRepository({this.latency = const Duration(milliseconds: 400)}) {
    // Seed: the user is part-way through the first pathway.
    _completed['pathway-1'] = {'pathway-1-step-1', 'pathway-1-step-2'};
  }

  final Duration latency;

  static const _defs = <_PathwayDef>[
    _PathwayDef('pathway-1', 'Foundations of faith', [
      _StepDef(
        PathwayStepType.video,
        'Why discipleship matters',
        '6 min video',
      ),
      _StepDef(
        PathwayStepType.devotional,
        'Rooted in Christ',
        '5 min devotional',
      ),
      _StepDef(
        PathwayStepType.quiz,
        'Quiz: the basics of faith',
        '6 questions',
      ),
      _StepDef(PathwayStepType.video, 'Living it out daily', '7 min video'),
    ]),
    _PathwayDef('pathway-2', 'Growing as a disciple', [
      _StepDef(
        PathwayStepType.devotional,
        'What does growth look like?',
        '5 min devotional',
      ),
      _StepDef(PathwayStepType.video, 'Habits of a disciple', '8 min video'),
      _StepDef(PathwayStepType.quiz, 'Quiz: spiritual habits', '5 questions'),
    ]),
    _PathwayDef('pathway-3', 'Leading your first group', [
      _StepDef(
        PathwayStepType.video,
        'What makes a good leader',
        '7 min video',
      ),
      _StepDef(
        PathwayStepType.devotional,
        'Serving before leading',
        '5 min devotional',
      ),
      _StepDef(
        PathwayStepType.quiz,
        'Quiz: leading your first group',
        '6 questions',
      ),
    ], UnlockRule(requiresCompleted: ['pathway-1'])),
    _PathwayDef('pathway-4', 'Serving your campus', [
      _StepDef(
        PathwayStepType.devotional,
        'A heart to serve',
        '5 min devotional',
      ),
      _StepDef(PathwayStepType.video, 'Finding where you fit', '6 min video'),
      _StepDef(
        PathwayStepType.quiz,
        'Quiz: serving your campus',
        '5 questions',
      ),
    ], UnlockRule(requiresCompleted: ['pathway-1'])),
  ];

  /// Seeded steps, for other fakes (e.g. the learning content catalogue).
  static List<({String id, PathwayStepType type, String title, String meta})>
  get stepCatalog => [
    for (final d in _defs)
      for (var i = 0; i < d.steps.length; i++)
        (
          id: d.stepId(i),
          type: d.steps[i].type,
          title: d.steps[i].title,
          meta: d.steps[i].meta,
        ),
  ];

  /// The only stored progress: which steps are done.
  final Map<String, Set<String>> _completed = {};

  _PathwayDef _def(String id) => _defs.firstWhere(
    (d) => d.id == id,
    orElse: () => throw ArgumentError('Unknown pathway id: $id'),
  );

  Set<String> _doneIn(String id) => _completed[id] ?? const {};

  Set<String> get _completedPathwayIds => {
    for (final d in _defs)
      if (_doneIn(d.id).length >= d.steps.length) d.id,
  };

  bool _isLocked(_PathwayDef d) => !d.rule.isSatisfied(_completedPathwayIds);

  Pathway _pathway(_PathwayDef d) => Pathway(
    id: d.id,
    title: d.title,
    stepCount: d.steps.length,
    completedSteps: _doneIn(d.id).length,
    unlockRule: d.rule,
    locked: _isLocked(d),
  );

  List<PathwayStep> _steps(_PathwayDef d) {
    final done = _doneIn(d.id);
    final locked = _isLocked(d);
    var currentAssigned = false;
    final steps = <PathwayStep>[];
    for (var i = 0; i < d.steps.length; i++) {
      final PathwayStepStatus status;
      if (done.contains(d.stepId(i))) {
        status = PathwayStepStatus.done;
      } else if (locked || currentAssigned) {
        status = PathwayStepStatus.locked;
      } else {
        currentAssigned = true;
        status = PathwayStepStatus.current;
      }
      steps.add(
        PathwayStep(
          id: d.stepId(i),
          pathwayId: d.id,
          index: i,
          type: d.steps[i].type,
          title: d.steps[i].title,
          meta: d.steps[i].meta,
          status: status,
        ),
      );
    }
    return steps;
  }

  @override
  Future<List<Pathway>> getPathways() async {
    await Future.delayed(latency);
    return List.unmodifiable(_defs.map(_pathway));
  }

  @override
  Future<List<PathwayStep>> getSteps(String pathwayId) async {
    await Future.delayed(latency);
    return List.unmodifiable(_steps(_def(pathwayId)));
  }

  @override
  Future<StepCompletion> completeStep(String pathwayId, String stepId) async {
    await Future.delayed(latency);
    final def = _def(pathwayId);
    if (_isLocked(def)) throw PathwayLockedError(pathwayId);
    final step = _steps(def).where((s) => s.id == stepId).firstOrNull;
    if (step == null) throw ArgumentError('Unknown step id: $stepId');
    if (step.status != PathwayStepStatus.current) {
      throw StepNotCurrentError(stepId);
    }
    (_completed[pathwayId] ??= {}).add(stepId);
    return StepCompletion(
      step: step.copyWith(status: PathwayStepStatus.done),
      pathwayCompleted: _doneIn(pathwayId).length >= def.steps.length,
    );
  }
}
