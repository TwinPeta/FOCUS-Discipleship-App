import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/celebration_screen.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/presentation/providers/activity_providers.dart';
import 'learning_providers.dart';

/// Screen 38: Badge earned (`/badge/:id/earned`). Several badges queue up:
/// Continue shows the next one, then returns to the previous screen.
class BadgeEarnedScreen extends ConsumerWidget {
  const BadgeEarnedScreen({super.key, required this.badgeId});

  final String badgeId;

  static String reasonFor(String badgeId) => switch (badgeId) {
    'first-steps' => 'You recorded your first activity. Keep going!',
    'quiz-finisher' => 'You finished your first quiz. Keep going!',
    'prayer-partner' =>
      'You prayed for ${BadgeRules.prayerPartnerThreshold} requests. Thank you!',
    'pathway-complete' => 'You completed a whole pathway. Keep going!',
    _ => 'Keep going!',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queued = ref.watch(badgeQueueProvider);
    final fromQueue = queued.where((b) => b.id == badgeId).firstOrNull;
    final all = ref.watch(badgesProvider).valueOrNull ?? const [];
    final badge = fromQueue ?? all.where((b) => b.id == badgeId).firstOrNull;
    final queue = ref.read(badgeQueueProvider.notifier);

    void next() {
      queue.dismiss(badgeId);
      final following = queue.next;
      if (following != null) {
        context.pushReplacement('/badge/${following.id}/earned');
      } else {
        context.canPop() ? context.pop() : context.go('/activity');
      }
    }

    return CelebrationScreen(
      icon: Icons.star_rounded,
      title: 'New badge',
      body: Column(
        children: [
          Text(
            badge?.name ?? 'Badge',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(reasonFor(badgeId)),
        ],
      ),
      actions: [
        AppPrimaryButton(
          label: 'See my badges',
          onPressed: () {
            queue.clear();
            context.go('/activity');
          },
        ),
        AppSecondaryButton(label: 'Continue', onPressed: next),
      ],
    );
  }
}
