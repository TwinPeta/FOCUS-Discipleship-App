import '../../../core/network/api_client.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
import '../domain/pathway.dart';
import '../domain/pathway_step.dart';
import 'pathway_repository.dart';

/// [PathwayRepository] backed by the FCU API. Starting a pathway (the
/// server's "enrollment") happens automatically with the first step.
class RemotePathwayRepository implements PathwayRepository {
  RemotePathwayRepository(this._api, {Outbox? outbox})
    : _outbox = outbox ?? Outbox(api: _api);

  final ApiClient _api;
  final Outbox _outbox;

  /// The saved pathway page with [stepId] done and the following step made
  /// current, so the step advances offline too.
  static Object? Function(String, Object?) _advance(
    String pathwayId,
    String stepId,
  ) => (key, json) {
    if (cachedPathOf(key) == '/pathways') {
      return patchEntity(json, pathwayId, (p) {
        p['steps_completed'] = ((p['steps_completed'] as int?) ?? 0) + 1;
        p['status'] ??= 'in_progress';
        return p;
      });
    }
    if (json is! Map<String, dynamic> || json['id'] != pathwayId) return json;
    final steps = [
      for (final s in (json['steps'] as List?) ?? const [])
        if (s is Map<String, dynamic>) Map<String, dynamic>.of(s),
    ];
    final i = steps.indexWhere((s) => s['id'] == stepId);
    if (i == -1 || steps[i]['status'] == 'done') return json;
    steps[i]['status'] = 'done';
    if (i + 1 < steps.length && steps[i + 1]['status'] != 'done') {
      steps[i + 1]['status'] = 'current';
    }
    return {
      ...json,
      'steps': steps,
      'steps_completed': ((json['steps_completed'] as int?) ?? 0) + 1,
    };
  };

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
      final stamp = DateTime.now().microsecondsSinceEpoch;
      try {
        await _outbox.write(
          OfflineWrite(
            method: 'PUT',
            endpoint: '/pathways/$pathwayId/enrollment',
            entityType: 'pathway_enroll',
            clientId: 'enroll-$pathwayId-$stamp',
            coalesceKey: 'pathway_enroll:$pathwayId',
          ),
        );
      } on ApiException catch (e) {
        if (e.code != 'already_enrolled') rethrow;
      }
      final steps0 = await getSteps(pathwayId).catchError((_) => <PathwayStep>[]);
      final i = steps0.indexWhere((s) => s.id == stepId);
      final written = await _outbox.write(
        OfflineWrite(
          method: 'POST',
          endpoint: '/pathways/$pathwayId/steps/$stepId/complete',
          entityType: 'pathway_step',
          clientId: 'step-$stepId-$stamp',
          coalesceKey: 'pathway_step:$pathwayId:$stepId',
          // Offline: the next step (if any) as the server would say.
          optimistic: {
            'next_step_id': i != -1 && i + 1 < steps0.length
                ? steps0[i + 1].id
                : null,
          },
          patch: _advance(pathwayId, stepId),
        ),
      );
      final result = objectOf(written.json);
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
