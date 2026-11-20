import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_policy.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../../core/widgets/password_field.dart';
import 'providers/auth_providers.dart';

/// Screen 21: Secure your account (`/join/password`, Step 2 of 3). The
/// account's email sits in the same autofill group as the new password, so
/// the phone's password manager saves the password under that login (the
/// email is what Sign in asks for) and fills it in later.
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
  late final _account = TextEditingController(
    text: ref.read(signUpControllerProvider).details?.email ?? '',
  );

  @override
  void dispose() {
    _account.dispose();
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
    // Ask the phone to offer "Save password?" for this account now.
    TextInput.finishAutofillContext();
    context.push('/join/verify');
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(signUpControllerProvider).details;
    return OnboardingScaffold(
      step: 2,
      xp: 10,
      xpReward: 10,
      title: 'Secure your account',
      subtitle: const Text('Choose a password for your account.'),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details != null) ...[
              _AccountField(controller: _account, username: details.username),
              const SizedBox(height: 16),
            ],
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

/// Read-only "Account" row: shows whose password this is, and tells the
/// password manager which login to save it under.
class _AccountField extends StatelessWidget {
  const _AccountField({required this.controller, required this.username});

  final TextEditingController controller;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.account_circle_outlined,
              color: AppColors.placeholder,
            ),
            helperText:
                '@$username · your phone can save the password for '
                'this account',
            helperMaxLines: 2,
            filled: true,
            fillColor: AppColors.cream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
