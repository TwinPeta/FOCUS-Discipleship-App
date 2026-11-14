import '../../../core/debug/debug_scenario.dart';
import '../domain/pathway_step.dart';
import 'providers/pathway_providers.dart';

/// Completes the current step of the first in-progress (or first) pathway.
final pathwayDebugScenarios = <DebugScenario>[
  DebugScenario(
    group: 'Pathways',
    name: 'Complete my current step',
    description: 'Marks the current step of "Foundations of faith" done.',
    run: (ref, _) async {
      const pathwayId = 'pathway-1';
      final steps = await ref.read(pathwayStepsProvider(pathwayId).future);
      final current = steps
          .where((s) => s.status == PathwayStepStatus.current)
          .firstOrNull;
      if (current == null) return 'Pathway already complete';
      final badges = await ref
          .read(pathwayStepsProvider(pathwayId).notifier)
          .completeStep(current.id);
      return [
        'Completed "${current.title}"',
        for (final b in badges) 'New badge: ${b.name}',
      ].join(' · ');
    },
  ),
];
