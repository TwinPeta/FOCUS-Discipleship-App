import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/error_snack.dart';
import 'providers/moderation_providers.dart';

/// Screen 12: Report sent, reached after submitting a report.
class ReportSentScreen extends ConsumerStatefulWidget {
  const ReportSentScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ReportSentScreen> createState() => _ReportSentScreenState();
}

class _ReportSentScreenState extends ConsumerState<ReportSentScreen> {
  bool _isBlocking = false;

  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block this user?'),
        content: const Text(
          'They will no longer be able to message you, and this conversation will be hidden from your inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBlocking = true);
    try {
      final thread = await ref
          .read(threadRepositoryProvider)
          .getThreadById(widget.threadId);
      if (thread != null) {
        await ref.read(moderationActionsProvider).block(thread.participant.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isBlocking = false);
        showErrorSnack(context, 'Could not block this user. Please try again.');
      }
      return;
    }

    if (!mounted) return;
    context.go('/messages');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          // Scrolls at large text scales instead of overflowing.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Report sent',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Thank you for helping keep the community safe. Our moderation team will review your report.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 18,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    label: 'Back to messages',
                    onPressed: () => context.go('/messages'),
                  ),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: 'Block this user',
                  isLoading: _isBlocking,
                  onPressed: _blockUser,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
