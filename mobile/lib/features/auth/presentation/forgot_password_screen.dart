import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/onboarding_scaffold.dart';

/// Screen 26: Forgot password (`/forgot-password`). Shows the same
/// confirmation whether or not the email has an account.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static String sentMessage(String email) =>
      'If an account exists for $email, we have sent a link to reset your '
      'password.';

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _sentTo;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _valid => Validators.email(_email.text) == null;

  Future<void> _send() async {
    if (_busy || !_valid) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (mounted) setState(() => _sentTo = email);
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToSignIn() =>
      context.canPop() ? context.pop() : context.go('/login');

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Forgot password',
      subtitle: const Text('Enter your email and we will send you a link.'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Email',
            controller: _email,
            placeholder: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _send(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Text(
            'Check your spam folder if it does not arrive in a few minutes.',
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.placeholder,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_sentTo != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: InfoBanner(
                icon: Icons.mark_email_read_outlined,
                child: Text(ForgotPasswordScreen.sentMessage(_sentTo!)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Send reset link',
            isLoading: _busy,
            onPressed: _valid ? _send : null,
          ),
          const SizedBox(height: 10),
          AppSecondaryButton(
            label: 'Back to sign in',
            onPressed: _backToSignIn,
          ),
        ],
      ),
    );
  }
}
