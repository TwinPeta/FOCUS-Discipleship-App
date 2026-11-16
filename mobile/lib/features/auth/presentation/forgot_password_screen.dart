import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_policy.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../../core/widgets/otp_field.dart';
import '../../../core/widgets/password_field.dart';
import '../data/auth_repository.dart';
import '../domain/otp_verifier.dart';
import 'verify_email_screen.dart' show ResendCodeRow;

/// Screen 26: Forgot password (`/forgot-password`), in two steps:
/// 1. the email: a 6-digit code is sent (the same confirmation whether or
///    not the email has an account);
/// 2. the code and a new password (twice), then back to Sign in.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static String sentMessage(String email) =>
      'If an account exists for $email, we have sent it a 6-digit code.';

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  String? _sentTo;
  String _code = '';
  String? _codeError;
  bool _busy = false;
  int _cooldown = 0;
  int _cooldownTotal = 1;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _emailValid => Validators.email(_email.text) == null;

  bool get _resetValid =>
      _code.length == 6 &&
      PasswordPolicy.isValid(_password.text) &&
      _password.text == _repeat.text;

  void _startCooldown(Duration wait) {
    _ticker?.cancel();
    final seconds = wait.inSeconds.clamp(1, 3600);
    setState(() {
      _cooldown = seconds;
      _cooldownTotal = seconds;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    if (_busy || !_emailValid) return;
    setState(() => _busy = true);
    final email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _sentTo = email);
      _startCooldown(OtpVerifier.resendCooldown);
    } on ResendTooSoon catch (e) {
      if (mounted) {
        setState(() => _sentTo = email);
        _startCooldown(e.wait);
      }
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_busy || !_resetValid || _sentTo == null) return;
    setState(() {
      _busy = true;
      _codeError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: _sentTo!,
            code: _code,
            password: _password.text,
          );
      if (!mounted) return;
      // Let the phone update the saved password for this account.
      TextInput.finishAutofillContext();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Password changed. Sign in with your new one.'),
          ),
        );
      context.go('/login');
    } on InvalidResetCode {
      if (mounted) {
        setState(
          () => _codeError =
              'That code is not right or has expired. Check it, or send a '
              'new one.',
        );
      }
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
    final sentTo = _sentTo;
    return OnboardingScaffold(
      title: sentTo == null ? 'Forgot password?' : 'Set a new password',
      subtitle: Text(
        sentTo == null
            ? 'Enter your email and we will send you a code.'
            : 'Enter the 6-digit code from your email and choose a new '
                  'password.',
      ),
      body: AutofillGroup(
        child: sentTo == null ? _emailStep() : _resetStep(sentTo),
      ),
    );
  }

  Widget _emailStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppTextField(
        label: 'Email',
        controller: _email,
        placeholder: 'you@example.com',
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email, AutofillHints.username],
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
      const SizedBox(height: 20),
      AppPrimaryButton(
        label: 'Send code',
        isLoading: _busy,
        onPressed: _emailValid ? _send : null,
      ),
      const SizedBox(height: 10),
      AppSecondaryButton(label: 'Back to sign in', onPressed: _backToSignIn),
    ],
  );

  Widget _resetStep(String sentTo) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        liveRegion: true,
        child: InfoBanner(
          icon: Icons.mark_email_read_outlined,
          child: Text(ForgotPasswordScreen.sentMessage(sentTo)),
        ),
      ),
      const SizedBox(height: 16),
      Text('Code', style: AppTextStyles.fieldLabel),
      const SizedBox(height: 6),
      OtpField(
        hasError: _codeError != null,
        onChanged: (value) => setState(() {
          _code = value;
          _codeError = null;
        }),
        onCompleted: (_) {},
      ),
      if (_codeError != null) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            _codeError!,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.error,
              fontSize: 13,
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      ResendCodeRow(
        secondsLeft: _cooldown,
        totalSeconds: _cooldownTotal,
        locked: false,
        onResend: _send,
      ),
      const SizedBox(height: 18),
      PasswordField(
        label: 'New password',
        controller: _password,
        placeholder: 'At least ${PasswordPolicy.minLength} characters',
        newPassword: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      PasswordField(
        label: 'Repeat new password',
        controller: _repeat,
        newPassword: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _reset(),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      PasswordRulesChecklist(password: _password.text, repeat: _repeat.text),
      const SizedBox(height: 20),
      AppPrimaryButton(
        label: 'Set new password',
        isLoading: _busy,
        onPressed: _resetValid ? _reset : null,
      ),
      const SizedBox(height: 10),
      AppSecondaryButton(
        label: 'Use a different email',
        onPressed: () => setState(() {
          _sentTo = null;
          _code = '';
          _codeError = null;
          _ticker?.cancel();
          _cooldown = 0;
        }),
      ),
    ],
  );
}
