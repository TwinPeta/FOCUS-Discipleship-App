import '../../../core/network/api_client.dart';
import '../domain/pathway.dart';
import '../domain/pathway_step.dart';
import 'pathway_repository.dart';

/// [PathwayRepository] backed by the FCU API. Starting a pathway (the
/// server's "enrollment") happens automatically with the first step.
class RemotePathwayRepository implements PathwayRepository {
  RemotePathwayRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Pathway>> getPathways() async {
    final json = objectOf(await _api.get('/pathways'));
    final items = itemsOf(json);
    final result = <Pathway>[];
    for (var i = 0; i < items.length; i++) {
      final j = items[i];
      final locked = j['status'] == 'locked';
      result.add(
        Pathway(
          id: j['id'] as String,
          title: (j['title'] as String?) ?? '',
          stepCount: (j['steps_total'] as int?) ?? 0,
          completedSteps: (j['steps_completed'] as int?) ?? 0,
          locked: locked,
          unlockRule: locked && i > 0
              ? UnlockRule(requiresCompleted: [items[i - 1]['id'] as String])
              : UnlockRule.always,
        ),
      );
    }
    return result;
  }

  static PathwayStepType _type(String? t) {
    switch (t) {
      case 'video':
        return PathwayStepType.video;
      case 'quiz':
        return PathwayStepType.quiz;
      default:
        return PathwayStepType.devotional;
    }
  }

  List<PathwayStep> _steps(Map<String, dynamic> detail) {
    final raw = detail['steps'];
    final list = raw is List
        ? raw.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    // Not started yet: the first step is the one to do next.
    final notStarted =
        (detail['steps_completed'] as int?) == 0 &&
        detail['status'] != 'locked';
    final pathwayId = detail['id'] as String;
    return [
      for (var i = 0; i < list.length; i++)
        PathwayStep(
          id: list[i]['id'] as String,
          pathwayId: pathwayId,
          index: i,
          type: _type(list[i]['type'] as String?),
          title: (list[i]['title'] as String?) ?? '',
          meta: (list[i]['duration_label'] as String?) ?? '',
          status: switch (list[i]['status']) {
            'done' => PathwayStepStatus.done,
            'current' => PathwayStepStatus.current,
            _ =>
              notStarted && i == 0
                  ? PathwayStepStatus.current
                  : PathwayStepStatus.locked,
          },
        ),
    ];
  }

  @override
  Future<List<PathwayStep>> getSteps(String pathwayId) async {
    try {
      final json = objectOf(await _api.get('/pathways/$pathwayId'));
      if (json == null) throw ArgumentError.value(pathwayId, 'pathwayId');
      return _steps(json);
    } on ApiException catch (e) {
      if (e.status == 404) throw ArgumentError.value(pathwayId, 'pathwayId');
      rethrow;
    }
  }

  @override
  Future<StepCompletion> completeStep(String pathwayId, String stepId) async {
    try {
      try {
        await _api.put('/pathways/$pathwayId/enrollment');
      } on ApiException catch (e) {
        if (e.code != 'already_enrolled') rethrow;
      }
      final result = objectOf(
        await _api.post('/pathways/$pathwayId/steps/$stepId/complete'),
      );
      final steps = await getSteps(pathwayId);
      final step = steps.firstWhere(
        (s) => s.id == stepId,
        orElse: () => throw StepNotCurrentError(stepId),
      );
      return StepCompletion(
        step: step,
        pathwayCompleted: result?['next_step_id'] == null,
      );
    } on ApiException catch (e) {
      if (e.code == 'pathway_locked') throw PathwayLockedError(pathwayId);
      if (e.status == 422 || e.status == 404 || e.code == 'not_enrolled') {
        throw StepNotCurrentError(stepId);
      }
      rethrow;
    }
  }
}
