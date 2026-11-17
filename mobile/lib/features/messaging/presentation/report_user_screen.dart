import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/dashed_rrect_painter.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../domain/report.dart';
import 'providers/messaging_providers.dart';
import 'report_flow.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/theme/app_gradients.dart';

/// Screen 11: Report a user (the [ReportFlow] with a chat screenshot),
/// reached from a conversation's report button.
class ReportUserScreen extends ConsumerStatefulWidget {
  const ReportUserScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  String? _screenshotPath;

  Future<void> _pickScreenshot() async {
    final picked = await pickPhoto(context, ref);
    if (picked == null || !mounted) return;
    setState(() => _screenshotPath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(threadByIdProvider(widget.threadId));
    final thread = threadAsync.valueOrNull;

    if (threadAsync.isLoading && !threadAsync.hasValue) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: const SafeArea(child: Skeleton(cardCount: 1)),
      );
    }
    if (thread == null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: threadAsync.hasError
              ? ErrorView(
                  onRetry: () =>
                      ref.invalidate(threadByIdProvider(widget.threadId)),
                )
              : const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Conversation not available',
                  body: 'This conversation no longer exists.',
                ),
        ),
      );
    }

    return ReportFlow(
      title: 'Report a user',
      subtitle: reportSubtitle('', thread.participant.name),
      question: 'What happened?',
      onSubmit: (reason, details) async {
        await ref
            .read(reportRepositoryProvider)
            .submitReport(
              Report(
                targetType: ReportTargetType.conversation,
                targetId: widget.threadId,
                targetUserId: thread.participant.id,
                reason: reason,
                details: details,
                screenshotPath: _screenshotPath,
              ),
            );
        if (context.mounted) {
          context.pushReplacement('/messages/${widget.threadId}/report/sent');
        }
      },
      extra: _ScreenshotCard(
        hasScreenshot: _screenshotPath != null,
        onPick: _pickScreenshot,
      ),
    );
  }
}

class _ScreenshotCard extends StatelessWidget {
  const _ScreenshotCard({required this.hasScreenshot, required this.onPick});

  final bool hasScreenshot;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedRRectPainter(radius: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screenshot of the chat',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Helps our team review what was said.',
              style: AppTextStyles.body.copyWith(
                fontSize: 12.5,
                color: AppColors.inkDeemphasized80,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: ElevatedButton(
                onPressed: onPick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  backgroundBuilder: AppGradients.buttonBackground(
                    BorderRadius.circular(10),
                  ),
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  hasScreenshot ? 'Replace screenshot' : 'Upload screenshot',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
