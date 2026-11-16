import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/celebration_screen.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../domain/warning.dart';
import 'moderation_providers.dart';

/// Screen 61: Moderator warning (`/warning/:id`, full screen). While it is
/// unacknowledged the warning guard keeps the member here (charter aside).
class ModeratorWarningScreen extends ConsumerStatefulWidget {
  const ModeratorWarningScreen({super.key, required this.warningId});

  final String warningId;

  @override
  ConsumerState<ModeratorWarningScreen> createState() =>
      _ModeratorWarningScreenState();
}

class _ModeratorWarningScreenState
    extends ConsumerState<ModeratorWarningScreen> {
  var _busy = false;

  Future<void> _understand(Warning w) async {
    if (_busy) return;
    if (w.acknowledged) return _continue();
    setState(() => _busy = true);
    try {
      await ref.read(warningRepositoryProvider).acknowledge(w.id);
      ref.invalidate(myWarningsProvider);
      await ref.read(myWarningsProvider.future);
      if (mounted) _continue();
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continue() =>
      context.canPop() ? context.pop() : context.go('/communities');

  @override
  Widget build(BuildContext context) {
    final warnings = ref.watch(myWarningsProvider);
    return warnings.when(
      loading: () =>
          Scaffold(backgroundColor: AppColors.page, body: const Skeleton()),
      error: (_, _) =>
          ErrorScreen(onRetry: () => ref.invalidate(myWarningsProvider)),
      data: (all) {
        final w = all.where((x) => x.id == widget.warningId).firstOrNull;
        if (w == null) return const ErrorScreen();
        return CelebrationScreen(
          icon: Icons.shield_outlined,
          iconBackground: AppColors.honey,
          title: 'A moderator sent you a warning',
          body: Text(
            'Reason: ${w.reason}. This message was hidden:',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          extra: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Text(
                w.preview,
                style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          actions: [
            AppPrimaryButton(
              label: w.acknowledged ? 'Continue' : 'I understand',
              isLoading: _busy,
              onPressed: _busy ? null : () => unawaited(_understand(w)),
            ),
            AppSecondaryButton(
              label: 'Read the charter',
              onPressed: () => context.push('/charter'),
            ),
          ],
        );
      },
    );
  }
}
