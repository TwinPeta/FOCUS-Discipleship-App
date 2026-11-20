import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/onboarding_scaffold.dart';

/// What a student needs to have ready, shown before the profile form.
const joinRequirements = <(IconData, String, String?)>[
  (Icons.badge_outlined, 'Full name', null),
  (Icons.alternate_email_rounded, 'Username', 'How others find you'),
  (Icons.cake_outlined, 'Date of birth', null),
  (Icons.public_rounded, 'Country', null),
  (Icons.mail_outline_rounded, 'Email', 'We send you a code to confirm it'),
  (Icons.phone_outlined, 'Phone number', null),
  (
    Icons.school_outlined,
    'School',
    'University (and your year of study) or institute',
  ),
  (
    Icons.church_outlined,
    'Home church (optional)',
    'Its name, location and pastor. You can add it later.',
  ),
];

/// Before the join form (`/join/start`): lists the details sign-up asks
/// for, so students can have them ready.
class JoinStartScreen extends StatelessWidget {
  const JoinStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Before you start',
      subtitle: const Text(
        'To create your profile you will need these details. '
        'It takes about 3 minutes.',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.lifted,
            ),
            child: Column(
              children: [
                for (final (icon, title, hint) in joinRequirements)
                  _RequirementRow(icon: icon, title: title, hint: hint),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You can add a profile photo too (optional). Next you set a '
            'password, confirm your email and accept the caregroup charter.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.inkDeemphasized80,
            ),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            label: "I'm ready",
            onPressed: () => context.push('/join'),
          ),
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size(44, 44),
            ),
            onPressed: () => context.push('/login'),
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Sign in',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.icon, required this.title, this.hint});

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                if (hint != null)
                  Text(
                    hint!,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: AppColors.inkDeemphasized80,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
