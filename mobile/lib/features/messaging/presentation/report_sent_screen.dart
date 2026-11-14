import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snack.dart';
import 'providers/moderation_providers.dart';
import 'report_flow.dart';

/// Screen 12: Report sent, after reporting a user from a conversation.
class ReportSentScreen extends ConsumerStatefulWidget {
  const ReportSentScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ReportSentScreen> createState() => _ReportSentScreenState();
}

class _ReportSentScreenState extends ConsumerState<ReportSentScreen> {
  bool _isBlocking = false;

  Future<void> _blockUser() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Block this user?',
      message:
          'They will no longer be able to message you, and this '
          'conversation will be hidden from your inbox.',
      confirmLabel: 'Block',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

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
    if (mounted) context.go('/messages');
  }

  @override
  Widget build(BuildContext context) {
    return ReportSentView(
      message:
          'Thank you for helping keep the community safe. Our moderation '
          'team will review your report.',
      primaryLabel: 'Back to messages',
      onPrimary: () => context.go('/messages'),
      secondaryLabel: 'Block this user',
      secondaryLoading: _isBlocking,
      onSecondary: _blockUser,
    );
  }
}
