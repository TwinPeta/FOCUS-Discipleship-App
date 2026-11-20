import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/celebration_screen.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import 'profile_providers.dart';

/// Screen 2g (Carebook): sign-up finished. "Newcomer" badge and the points
/// earned on the way ([signUpXpTotal]), then the campus or the profile.
class JoinDoneScreen extends ConsumerWidget {
  const JoinDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentProfileProvider)?.fullName.split(' ').first;
    return CelebrationScreen(
      icon: Icons.star_rounded,
      title: name == null || name.isEmpty
          ? 'You are all set!'
          : 'You are all set, $name!',
      body: const Text(
        'Your profile is ready. You earned your first points.',
        textAlign: TextAlign.center,
      ),
      extra: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'BADGE UNLOCKED: NEWCOMER',
              style: AppTextStyles.chip.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.amberDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '+$signUpXpTotal XP · Level 1',
                  style: AppTextStyles.cardTitle,
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        AppPrimaryButton(
          label: 'Join my campus',
          onPressed: () => context.go('/communities'),
        ),
        AppSecondaryButton(
          label: 'Complete my profile',
          onPressed: () => context.go('/settings/profile'),
        ),
      ],
    );
  }
}
