import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../../core/widgets/otp_field.dart';
import '../data/auth_repository.dart';
import '../domain/otp_verifier.dart';
import 'providers/auth_providers.dart';

/// Screen 22: Check your email (`/join/verify`, Step 2 of 3).
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  String _code = '';
  String? _error;
  DateTime? _lockedUntil;
  int _cooldown = 0;
  bool _verifying = false;
  Timer? _ticker;

  String get _email => ref.read(signUpControllerProvider).details?.email ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _send(initial: true));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startCooldown(Duration wait) {
    _ticker?.cancel();
    setState(() => _cooldown = wait.inSeconds.clamp(1, 999));
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        _cooldown--;
        if (_lockedUntil != null && !DateTime.now().isBefore(_lockedUntil!)) {
          _lockedUntil = null;
          _error = null;
        }
      });
      if (_cooldown <= 0 && _lockedUntil == null) timer.cancel();
    });
  }

  Future<void> _send({bool initial = false}) async {
    try {
      await ref.read(authRepositoryProvider).sendVerificationCode(_email);
      if (!mounted) return;
      _startCooldown(OtpVerifier.resendCooldown);
      if (!initial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We sent you a new code.')),
        );
      }
    } on ResendTooSoon catch (e) {
      if (mounted) _startCooldown(e.wait);
    } catch (_) {
      if (mounted) showErrorSnack(context);
    }
  }

  Future<void> _verify() async {
    if (_verifying || _code.length != 6 || _lockedUntil != null) return;
    setState(() => _verifying = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyCode(_email, _code);
      if (!mounted) return;
      switch (result.status) {
        case OtpStatus.verified:
          ref.read(signUpControllerProvider.notifier).markVerified();
          unawaited(context.push('/join/consent'));
        case OtpStatus.wrong:
          setState(
            () => _error =
                'That code is not right. ${result.attemptsLeft} '
                '${result.attemptsLeft == 1 ? 'attempt' : 'attempts'} left.',
          );
        case OtpStatus.locked:
          setState(() {
            _lockedUntil = result.lockedUntil;
            _error =
                'Too many attempts. For your safety, try again in '
                '${OtpVerifier.lockDuration.inMinutes} minutes.';
          });
          _startCooldown(OtpVerifier.lockDuration);
      }
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(signUpControllerProvider).details?.email ?? '';
    final locked = _lockedUntil != null;
    return OnboardingScaffold(
      step: 2,
      title: 'Check your email',
      subtitle: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'We sent a 6-digit code to '),
            TextSpan(
              text: email,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OtpField(
            enabled: !locked,
            hasError: _error != null,
            onChanged: (value) => setState(() {
              _code = value;
              if (!locked) _error = null;
            }),
            onCompleted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: AppTextStyles.fieldLabel.copyWith(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Did not get it?', style: AppTextStyles.body),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: _cooldown > 0 || locked ? null : _send,
                child: Text(
                  _cooldown > 0 && !locked
                      ? 'Send a new code in ${_cooldown}s'
                      : 'Send a new code',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: AppPrimaryButton(
        label: 'Verify email',
        isLoading: _verifying,
        onPressed: _code.length == 6 && !locked ? _verify : null,
      ),
    );
  }
}
