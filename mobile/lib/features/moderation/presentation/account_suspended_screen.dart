import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/celebration_screen.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'moderation_providers.dart';

/// "21 November 2026".
String formatSuspensionDate(DateTime d) => formatLongDate(d);

/// Screen 60: Account suspended (`/suspended`, full screen). The suspended
/// guard (first in the chain) keeps the account here until it ends.
class AccountSuspendedScreen extends ConsumerStatefulWidget {
  const AccountSuspendedScreen({super.key});

  @override
  ConsumerState<AccountSuspendedScreen> createState() =>
      _AccountSuspendedScreenState();
}

class _AccountSuspendedScreenState
    extends ConsumerState<AccountSuspendedScreen> {
  var _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        showErrorSnack(context);
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suspension = ref.watch(suspensionProvider);
    return PopScope(
      canPop: false,
      child: suspension.when(
        loading: () =>
            Scaffold(backgroundColor: AppColors.page, body: const Skeleton()),
        error: (_, _) =>
            ErrorScreen(onRetry: () => ref.invalidate(suspensionProvider)),
        data: (s) => CelebrationScreen(
          icon: Icons.block_rounded,
          iconBackground: AppColors.honey,
          title: 'Your account is suspended',
          body: Column(
            children: [
              Text(
                s == null
                    ? 'Your account is suspended.'
                    : 'Reason: ${s.reason}. Until '
                          '${formatSuspensionDate(s.until)}.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'You can read the caregroup charter or write to the support '
                'team if you think this is a mistake.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            AppPrimaryButton(
              label: 'Read the charter',
              onPressed: () => context.push('/charter'),
            ),
            AppSecondaryButton(
              label: 'Sign out',
              isLoading: _signingOut,
              onPressed: _signingOut ? null : () => unawaited(_signOut()),
            ),
          ],
        ),
      ),
    );
  }
}
