import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/pathways/data/pathway_repository.dart';
import 'package:focus_1/features/pathways/domain/pathway.dart';
import 'package:focus_1/features/pathways/domain/pathway_step.dart';

void main() {
  test('pathways 3 and 4 stay locked until pathway 1 is completed', () async {
    final repo = FakePathwayRepository();
    final pathways = await repo.getPathways();

    bool isLocked(String id) {
      final pathway = pathways.firstWhere((p) => p.id == id);
      if (pathway.unlocksAfterPathwayId == null) return false;
      final prerequisite =
          pathways.firstWhere((p) => p.id == pathway.unlocksAfterPathwayId);
      return prerequisite.status != PathwayStatus.completed;
    }

    expect(isLocked('pathway-1'), isFalse);
    expect(isLocked('pathway-2'), isFalse);
    expect(isLocked('pathway-3'), isTrue);
    expect(isLocked('pathway-4'), isTrue);
  });

  test('completing steps advances sequentially and completing the pathway unlocks dependants', () async {
    final repo = FakePathwayRepository();
    var steps = await repo.getSteps('pathway-1');
    expect(steps.where((s) => s.status == PathwayStepStatus.current).single.id,
        'pathway-1-step-3');

    // Complete the current (3rd) step: the 4th unlocks, pathway stays in progress.
    await repo.completeStep('pathway-1', 'pathway-1-step-3');
    steps = await repo.getSteps('pathway-1');
    expect(steps[2].status, PathwayStepStatus.done);
    expect(steps[3].status, PathwayStepStatus.current);
    var pathways = await repo.getPathways();
    var pathway1 = pathways.firstWhere((p) => p.id == 'pathway-1');
    expect(pathway1.status, PathwayStatus.inProgress);
    expect(pathway1.currentStepIndex, 3);

    // Complete the last step: the pathway finishes and dependants unlock.
    await repo.completeStep('pathway-1', 'pathway-1-step-4');
    pathways = await repo.getPathways();
    pathway1 = pathways.firstWhere((p) => p.id == 'pathway-1');
    expect(pathway1.status, PathwayStatus.completed);

    final pathway3 = pathways.firstWhere((p) => p.id == 'pathway-3');
    final prerequisite =
        pathways.firstWhere((p) => p.id == pathway3.unlocksAfterPathwayId);
    expect(prerequisite.status, PathwayStatus.completed);
  });
}
