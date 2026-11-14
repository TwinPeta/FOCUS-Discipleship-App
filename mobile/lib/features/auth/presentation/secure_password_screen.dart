import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/password_policy.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../../core/widgets/password_field.dart';
import 'providers/auth_providers.dart';

/// Screen 21: Secure your account (`/join/password`, Step 2 of 3).
class SecurePasswordScreen extends ConsumerStatefulWidget {
  const SecurePasswordScreen({super.key});

  @override
  ConsumerState<SecurePasswordScreen> createState() =>
      _SecurePasswordScreenState();
}

class _SecurePasswordScreenState extends ConsumerState<SecurePasswordScreen> {
  // Plain text lives only in these field controllers, never in app state.
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  final _repeatFocus = FocusNode();

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    _repeatFocus.dispose();
    super.dispose();
  }

  bool get _valid =>
      PasswordPolicy.isValid(_password.text) && _password.text == _repeat.text;

  void _continue() {
    if (!_valid) return;
    ref.read(signUpControllerProvider.notifier).setPassword(_password.text);
    context.push('/join/verify');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      title: 'Secure your account',
      subtitle: const Text('Choose a password for your account.'),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PasswordField(
              label: 'Password',
              controller: _password,
              placeholder: 'At least ${PasswordPolicy.minLength} characters',
              newPassword: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _repeatFocus.requestFocus(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Repeat password',
              controller: _repeat,
              focusNode: _repeatFocus,
              newPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continue(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            PasswordRulesChecklist(
              password: _password.text,
              repeat: _repeat.text,
            ),
          ],
        ),
      ),
      bottom: AppPrimaryButton(
        label: 'Continue',
        onPressed: _valid ? _continue : null,
      ),
    );
  }
}
