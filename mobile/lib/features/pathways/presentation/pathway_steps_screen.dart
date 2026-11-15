import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../learning/presentation/learning_providers.dart';
import '../domain/pathway.dart';
import '../domain/pathway_step.dart';
import 'providers/pathway_providers.dart';
import 'widgets/pathway_progress_bar.dart';
import '../../../core/theme/app_gradients.dart';

/// Screen 19: Pathway steps, reached from the Pathways tab.
class PathwayStepsScreen extends ConsumerWidget {
  const PathwayStepsScreen({
    super.key,
    required this.communityId,
    required this.pathwayId,
  });

  final String communityId;
  final String pathwayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathwaysAsync = ref.watch(pathwaysProvider);
    final stepsAsync = ref.watch(pathwayStepsProvider(pathwayId));

    if ((pathwaysAsync.isLoading && !pathwaysAsync.hasValue) ||
        (stepsAsync.isLoading && !stepsAsync.hasValue)) {
      return const Scaffold(backgroundColor: AppColors.page, body: Skeleton());
    }

    final pathway = pathwaysAsync.valueOrNull
        ?.where((p) => p.id == pathwayId)
        .firstOrNull;
    final steps = stepsAsync.valueOrNull;
    if (pathway == null || steps == null) {
      return ErrorScreen(
        onRetry: () {
          ref.invalidate(pathwaysProvider);
          ref.invalidate(pathwayStepsProvider(pathwayId));
        },
      );
    }

    if (pathway.locked) {
      // Deep links can't bypass the unlock rule.
      return AmberHeaderScaffold(
        backFallback: '/community/$communityId/pathways',
        title: pathway.title,
        subtitle: 'Locked',
        body: const SingleChildScrollView(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'This pathway is locked',
            body: 'Finish the pathways before it to unlock it.',
          ),
        ),
      );
    }

    // Completion happens in the viewer ("Mark as complete" / quiz pass).
    void onContinue(PathwayStep step) => context.push(
      learningRoute(
        kindForStep(step.type),
        step.id,
        pathwayId: pathwayId,
        communityId: communityId,
      ),
    );

    return AmberHeaderScaffold(
      backFallback: '/community/$communityId/pathways',
      title: pathway.title,
      subtitle: pathway.status == PathwayStatus.completed
          ? 'Completed'
          : 'Step ${pathway.currentStepIndex + 1} of ${pathway.stepCount}',
      headerExtra: PathwayProgressBar(progress: pathway.progress),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: steps.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _StepRow(
          key: ValueKey(steps[index].id),
          step: steps[index],
          onContinue: () => onContinue(steps[index]),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({super.key, required this.step, required this.onContinue});

  final PathwayStep step;
  final VoidCallback onContinue;

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
        color: step.status == PathwayStepStatus.current
            ? AppColors.honey
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: step.status == PathwayStepStatus.locked
            ? null
            : Border.all(color: AppColors.ink, width: 2),
        boxShadow: step.status == PathwayStepStatus.locked
            ? null
            : AppShadows.soft,
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
              ],
            ),
          ),
          if (step.status == PathwayStepStatus.current) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  backgroundBuilder: AppGradients.buttonBackground(
                    BorderRadius.circular(10),
                  ),
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
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
