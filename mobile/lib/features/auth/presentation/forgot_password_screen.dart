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
import 'providers/auth_providers.dart';

/// Screen 26: Forgot password (`/forgot-password`).
///
/// Step 1 asks for the email and sends a 6-digit code; it shows the same
/// confirmation whether or not the email has an account. Step 2 takes the
/// code and a new password, changes it and signs the student in.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static String sentMessage(String email) =>
      'If an account exists for $email, we have sent a 6-digit code to '
      'reset your password. It works for 10 minutes.';

  static const codeError =
      'That code is not right or has expired. Check it, or send a new one.';

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  final _repeatFocus = FocusNode();
  String? _sentTo;
  String _code = '';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    _repeatFocus.dispose();
    super.dispose();
  }

  bool get _emailValid => Validators.email(_email.text) == null;

  bool get _canReset =>
      !_busy &&
      _code.length == 6 &&
      PasswordPolicy.isValid(_password.text) &&
      _password.text == _repeat.text;

  Future<void> _send({bool again = false}) async {
    final email = again ? _sentTo! : _email.text.trim();
    if (_busy || (!again && !_emailValid)) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _sentTo = email;
        _error = null;
      });
      if (again) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We sent you a new code.')),
        );
      }
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_canReset) return;
    final email = _sentTo!;
    final password = _password.text;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(email, _code, password);
      await ref.read(authControllerProvider.notifier).signIn(email, password);
      if (mounted) context.go('/communities');
    } on InvalidResetCode {
      if (mounted) setState(() => _error = ForgotPasswordScreen.codeError);
    } on InvalidCredentials {
      // The password changed but signing in did not go through: send the
      // student to sign in with it.
      if (mounted) context.go('/login');
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
      title: sentTo == null ? 'Forgot password' : 'Set a new password',
      subtitle: Text(
        sentTo == null
            ? 'Enter your email and we will send you a code.'
            : 'Enter the code from your email and choose a new password.',
      ),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sentTo == null ? _emailStep() : _resetStep(sentTo),
        ),
      ),
    );
  }

  List<Widget> _emailStep() => [
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
    const SizedBox(height: 20),
    AppPrimaryButton(
      label: 'Send code',
      isLoading: _busy,
      onPressed: _emailValid ? _send : null,
    ),
    const SizedBox(height: 10),
    AppSecondaryButton(label: 'Back to sign in', onPressed: _backToSignIn),
  ];

  List<Widget> _resetStep(String sentTo) => [
    Semantics(
      liveRegion: true,
      child: InfoBanner(
        icon: Icons.mark_email_read_outlined,
        child: Text(ForgotPasswordScreen.sentMessage(sentTo)),
      ),
    ),
    const SizedBox(height: 16),
    OtpField(
      hasError: _error != null,
      onChanged: (value) => setState(() {
        _code = value;
        _error = null;
      }),
    ),
    if (_error != null) ...[
      const SizedBox(height: 8),
      Semantics(
        liveRegion: true,
        child: Text(
          _error!,
          style: AppTextStyles.fieldLabel.copyWith(color: AppColors.error),
        ),
      ),
    ],
    const SizedBox(height: 16),
    PasswordField(
      label: 'New password',
      controller: _password,
      placeholder: 'At least ${PasswordPolicy.minLength} characters',
      newPassword: true,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _repeatFocus.requestFocus(),
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 12),
    PasswordField(
      label: 'Repeat new password',
      controller: _repeat,
      focusNode: _repeatFocus,
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
      onPressed: _canReset ? _reset : null,
    ),
    const SizedBox(height: 10),
    AppSecondaryButton(
      label: 'Send a new code',
      onPressed: _busy ? null : () => _send(again: true),
    ),
    const SizedBox(height: 4),
    Text(
      'Check your spam folder if the code does not arrive in a few minutes.',
      textAlign: TextAlign.center,
      style: AppTextStyles.fieldLabel.copyWith(
        color: AppColors.placeholder,
        fontWeight: FontWeight.w500,
      ),
    ),
    const SizedBox(height: 4),
    TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(44, 44),
      ),
      onPressed: _backToSignIn,
      child: const Text('Back to sign in'),
    ),
  ];
}
