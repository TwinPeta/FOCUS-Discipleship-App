import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../../core/widgets/password_field.dart';
import '../data/auth_repository.dart';
import 'providers/auth_providers.dart';
import '../../../core/theme/app_gradients.dart';

/// Screen 25: Sign in (`/login`). One generic error that never says
/// whether the email or the password was wrong.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const genericError = 'Email or password is incorrect';

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy &&
      Validators.email(_email.text) == null &&
      _password.text.isNotEmpty;

  Future<void> _signIn() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text.trim(), _password.text);
      // Signed in: let the phone save (or update) these details.
      TextInput.finishAutofillContext();
      if (mounted) context.go('/communities');
    } on InvalidCredentials {
      if (mounted) setState(() => _error = SignInScreen.genericError);
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      onBack: () => context.go('/'),
      header: const _LogoBlock(),
      title: 'Welcome back',
      subtitle: const Text('Sign in to see your communities.'),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email',
              controller: _email,
              placeholder: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.username,
              ],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Password',
              controller: _password,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(),
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => context.push('/forgot-password'),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.error, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Sign in',
              isLoading: _busy,
              onPressed: _canSubmit ? _signIn : null,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('New here?', style: AppTextStyles.body),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => context.go('/join/start'),
                  child: const Text(
                    'Explore communities',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'FCU, Fellowship of Christian Unions',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            ),
            alignment: Alignment.center,
            child: Text(
              'FCU',
              style: AppTextStyles.cardTitle.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fellowship of\nChristian Unions',
              style: AppTextStyles.cardTitle.copyWith(height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}
