import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../activity/domain/badge.dart';
import 'learning_providers.dart';
import 'widgets/viewer_parts.dart';

/// Screen 36: Quiz result (`/quiz/:id/result`).
class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key, required this.id, required this.origin});

  final String id;
  final LearningOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptAsync = ref.watch(lastQuizAttemptProvider(id));
    final quizAsync = ref.watch(quizProvider(id));
    if (attemptAsync.isLoading || quizAsync.isLoading) {
      return const Scaffold(backgroundColor: AppColors.page, body: Skeleton());
    }
    final attempt = attemptAsync.valueOrNull;
    final quiz = quizAsync.valueOrNull;
    if (attempt == null || quiz == null) {
      return ErrorScreen(
        onRetry: () => ref.invalidate(lastQuizAttemptProvider(id)),
      );
    }
    final queued = ref.watch(badgeQueueProvider);
    final query = GoRouterState.of(context).uri.query;
    final suffix = query.isEmpty ? '' : '?$query';
    final passPercent = (quiz.passMark * 100).round();

    void backToResources() {
      final community = origin.communityId;
      if (origin.pathwayId != null && community != null) {
        context.go('/community/$community/pathways/${origin.pathwayId}');
      } else if (community != null) {
        context.go('/community/$community/resources');
      } else {
        leaveViewer(context, origin);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Semantics(
                        label:
                            '${attempt.correct} out of ${attempt.total} correct',
                        excludeSemantics: true,
                        child: Column(
                          children: [
                            Text(
                              '${attempt.correct}/${attempt.total}',
                              style: AppTextStyles.celebrationTitle.copyWith(
                                fontSize: 64,
                              ),
                            ),
                            Text(
                              'correct',
                              style: AppTextStyles.sectionHeading,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        attempt.passed ? 'Well done!' : 'Not quite yet',
                        style: AppTextStyles.celebrationTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        attempt.passed
                            ? 'You passed this quiz.'
                            : 'You need $passPercent% to pass. Try again when you are ready.',
                        style: AppTextStyles.body.copyWith(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      for (final badge in queued) ...[
                        const SizedBox(height: 20),
                        _BadgeCard(badge: badge),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!attempt.passed) ...[
                    AppPrimaryButton(
                      label: 'Try again',
                      onPressed: () =>
                          context.pushReplacement('/quiz/$id$suffix'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  AppSecondaryButton(
                    label: 'Review my answers',
                    onPressed: () => context.push('/quiz/$id/review$suffix'),
                  ),
                  const SizedBox(height: 10),
                  if (attempt.passed)
                    AppPrimaryButton(
                      label: 'Back to resources',
                      onPressed: backToResources,
                    )
                  else
                    AppSecondaryButton(
                      label: 'Back to resources',
                      onPressed: backToResources,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final AppBadge badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New badge: ${badge.name}. Open',
      excludeSemantics: true,
      child: Material(
        color: AppColors.honey,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          onTap: () => context.push('/badge/${badge.id}/earned'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'New badge: ${badge.name}',
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
