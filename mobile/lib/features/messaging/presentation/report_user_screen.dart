import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_area.dart';
import '../../../core/widgets/dashed_rrect_painter.dart';
import '../domain/report.dart';
import '../domain/thread.dart';
import 'providers/messaging_providers.dart';

/// Screen 11: Report a user, reached from a conversation's report button.
class ReportUserScreen extends ConsumerStatefulWidget {
  const ReportUserScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  final _detailsController = TextEditingController();
  ReportReason? _reason;
  String? _screenshotPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_isSubmitting && _reason != null;

  Future<void> _pickScreenshot() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _screenshotPath = picked.path);
  }

  Future<void> _submit(Thread thread) async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    final report = Report(
      targetUserId: thread.participant.id,
      threadId: widget.threadId,
      reason: _reason!,
      details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
      screenshotPath: _screenshotPath,
    );
    await ref.read(reportRepositoryProvider).submitReport(report);

    if (!mounted) return;
    context.pushReplacement('/messages/${widget.threadId}/report/sent');
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(threadByIdProvider(widget.threadId));

    return threadAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.page,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.page,
        body: Center(child: Text('Could not load this conversation.', style: AppTextStyles.body)),
      ),
      data: (thread) {
        if (thread == null) {
          return Scaffold(
            backgroundColor: AppColors.page,
            body: Center(child: Text('Could not load this conversation.', style: AppTextStyles.body)),
          );
        }

        return AmberHeaderScaffold(
          title: 'Report a user',
          subtitleWidget: Text.rich(
            TextSpan(
              style: AppTextStyles.amberHeaderSubtitle,
              children: [
                const TextSpan(text: 'You are reporting '),
                TextSpan(
                  text: thread.participant.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What happened?',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                for (final reason in ReportReason.values) ...[
                  _ReasonRow(
                    label: reason.label,
                    selected: _reason == reason,
                    onTap: () => setState(() => _reason = reason),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                AppTextArea(
                  label: 'Add details (optional)',
                  controller: _detailsController,
                  placeholder: 'Anything else that would help us review this',
                  minHeight: 72,
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'Upload a screenshot of the chat',
                  child: CustomPaint(
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
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _pickScreenshot,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amber,
                                foregroundColor: AppColors.ink,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(_screenshotPath != null ? 'Replace screenshot' : 'Upload'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomBar: Column(
            children: [
              AppPrimaryButton(
                label: 'Send report',
                height: 54,
                isLoading: _isSubmitting,
                onPressed: _canSubmit ? () => _submit(thread) : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Reports are reviewed by the FCU moderation team.',
                style: AppTextStyles.fieldLabel.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkDeemphasized80,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.honey : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: AppColors.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
