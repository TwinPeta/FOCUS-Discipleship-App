import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/check_row.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../domain/auth_models.dart';
import 'charter_screen.dart';
import 'providers/auth_providers.dart';

/// Screen 23: Before you join (`/join/consent`, Step 3 of 3). Every box
/// starts unticked: consent must be an explicit action.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _charter = false;
  bool _participation = false;
  bool _mentorContact = false;
  bool _joining = false;

  bool get _canJoin => _charter && _participation && !_joining;

  Future<void> _join() async {
    if (!_canJoin) return;
    setState(() => _joining = true);
    try {
      final profile = await ref
          .read(signUpControllerProvider.notifier)
          .complete(
            Consent(
              charterAccepted: _charter,
              participationAccepted: _participation,
              mentorContactAllowed: _mentorContact,
              acceptedAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      // The campus General community is derived from the profile, so it is
      // joined as soon as the profile exists.
      context.go(isMinor(profile) ? '/join/guardian' : '/communities');
    } catch (_) {
      if (mounted) {
        setState(() => _joining = false);
        showErrorSnack(context, 'We could not create your account. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(signUpControllerProvider).details;
    final minor = details != null && isMinor(details);
    return OnboardingScaffold(
      step: 3,
      title: 'Before you join',
      subtitle: const Text('Please read and accept to continue.'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.honey,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community charter', style: AppTextStyles.cardTitle),
                const SizedBox(height: 8),
                for (final rule in CharterScreen.summary)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(rule, style: AppTextStyles.body)),
                      ],
                    ),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => context.push('/charter'),
                  child: const Text(
                    'Read the full charter',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckRow(
            label: 'I accept the community charter (required)',
            value: _charter,
            onChanged: (v) => setState(() => _charter = v),
          ),
          const SizedBox(height: 10),
          CheckRow(
            label: 'I agree to take part in community spaces (required)',
            value: _participation,
            onChanged: (v) => setState(() => _participation = v),
          ),
          const SizedBox(height: 10),
          CheckRow(
            label: 'I agree that a mentor may contact me (optional)',
            value: _mentorContact,
            onChanged: (v) => setState(() => _mentorContact = v),
          ),
          if (minor) ...[
            const SizedBox(height: 16),
            const InfoBanner(
              icon: Icons.family_restroom_rounded,
              child: Text('Under 18? A parent or guardian must confirm.'),
            ),
          ],
        ],
      ),
      bottom: AppPrimaryButton(
        label: 'Join my campus',
        isLoading: _joining,
        onPressed: _canJoin ? _join : null,
      ),
    );
  }
}
