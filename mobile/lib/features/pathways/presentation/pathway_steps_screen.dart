import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../activity/domain/activity_event.dart';
import '../../activity/presentation/providers/activity_providers.dart';
import '../domain/pathway.dart';
import '../domain/pathway_step.dart';
import 'providers/pathway_providers.dart';

/// Screen 19: Pathway steps, reached from the Pathways tab.
class PathwayStepsScreen extends ConsumerWidget {
  const PathwayStepsScreen({super.key, required this.pathwayId});

  final String pathwayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathwaysAsync = ref.watch(pathwaysProvider);
    final stepsAsync = ref.watch(pathwayStepsProvider(pathwayId));

    if (pathwaysAsync.isLoading || stepsAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.page,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pathways = pathwaysAsync.valueOrNull;
    final steps = stepsAsync.valueOrNull;
    Pathway? pathway;
    if (pathways != null) {
      for (final p in pathways) {
        if (p.id == pathwayId) pathway = p;
      }
    }
    if (pathway == null || steps == null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: Center(
          child: Text('Could not load this pathway.', style: AppTextStyles.body),
        ),
      );
    }

    final progress = pathway.stepCount == 0 ? 0.0 : pathway.currentStepIndex / pathway.stepCount;

    return AmberHeaderScaffold(
      title: pathway.title,
      subtitle: pathway.status == PathwayStatus.completed
          ? 'Completed'
          : 'Step ${pathway.currentStepIndex + 1} of ${pathway.stepCount}',
      headerExtra: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0, 1),
            child: Container(color: AppColors.ink),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepRow(
              step: steps[i],
              onContinue: () async {
                if (steps[i].type == PathwayStepType.video) {
                  await ref.read(activityRepositoryProvider).record(
                    ActivityEvent(
                      type: 'video_watched',
                      label: 'Watched "${steps[i].title}"',
                      at: DateTime.now(),
                    ),
                  );
                  ref.invalidate(activityEventsProvider);
                  ref.invalidate(badgesProvider);
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This step\'s viewer is coming soon')),
                );
              },
              onDebugComplete: () async {
                final newlyEarned = await ref
                    .read(pathwayStepsProvider(pathwayId).notifier)
                    .completeStep(steps[i].id);
                if (!context.mounted) return;
                for (final badge in newlyEarned) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New badge earned: ${badge.name}!')),
                  );
                }
              },
            ),
            if (i != steps.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.onContinue,
    required this.onDebugComplete,
  });

  final PathwayStep step;
  final VoidCallback onContinue;
  final VoidCallback onDebugComplete;

  IconData get _typeIcon => switch (step.type) {
    PathwayStepType.video => Icons.play_arrow_rounded,
    PathwayStepType.devotional => Icons.menu_book_rounded,
    PathwayStepType.quiz => Icons.quiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: step.status == PathwayStepStatus.current ? AppColors.honey : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: step.status == PathwayStepStatus.locked
            ? null
            : Border.all(color: AppColors.ink, width: 2),
        boxShadow: step.status == PathwayStepStatus.locked ? null : AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: switch (step.status) {
                PathwayStepStatus.done => AppColors.amber,
                PathwayStepStatus.current => AppColors.white,
                PathwayStepStatus.locked => AppColors.cream,
              },
              shape: BoxShape.circle,
              border: step.status == PathwayStepStatus.locked
                  ? null
                  : Border.all(color: AppColors.ink, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(
              step.status == PathwayStepStatus.done
                  ? Icons.check_rounded
                  : step.status == PathwayStepStatus.locked
                      ? Icons.lock_outline_rounded
                      : _typeIcon,
              color: AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  step.meta,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    color: AppColors.inkDeemphasized80,
                  ),
                ),
                if (step.status == PathwayStepStatus.current && kDebugMode) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onDebugComplete,
                    child: Text(
                      'Prototype: mark step complete',
                      style: AppTextStyles.fieldLabel.copyWith(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (step.status == PathwayStepStatus.current) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );

    return step.status == PathwayStepStatus.locked
        ? Opacity(opacity: 0.55, child: card)
        : card;
  }
}
