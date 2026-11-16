import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_text_area.dart';
import '../../../core/widgets/celebration_screen.dart';
import '../../../core/widgets/error_snack.dart';
import '../domain/report.dart';

/// The amber header subtitle: "You are reporting {lead}**{name}**." —
/// `reportSubtitle('', 'Ann')` for a user, `reportSubtitle('a post by ',
/// 'Ann')` for content.
Widget reportSubtitle(String lead, String name) {
  return Text.rich(
    TextSpan(
      style: AppTextStyles.amberHeaderSubtitle,
      children: [
        TextSpan(text: 'You are reporting $lead'),
        TextSpan(
          text: name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const TextSpan(text: '.'),
      ],
    ),
  );
}

/// The one report form (screens 11 and 41): five reasons, optional
/// details, an optional [extra] section (the chat screenshot) and **Send
/// report**, disabled until a reason is chosen and while sending.
///
/// [onSubmit] stores the report and navigates on; if it throws, the form
/// stays filled in and shows an error.
class ReportFlow extends StatefulWidget {
  const ReportFlow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.question,
    required this.onSubmit,
    this.extra,
    this.backFallback = '/communities',
  });

  final String title;
  final Widget subtitle;
  final String question;
  final Future<void> Function(ReportReason reason, String? details) onSubmit;
  final Widget? extra;

  /// Back on a deep link (nothing to pop).
  final String backFallback;

  @override
  State<ReportFlow> createState() => _ReportFlowState();
}

class _ReportFlowState extends State<ReportFlow> {
  final _detailsController = TextEditingController();
  ReportReason? _reason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final details = _detailsController.text.trim();
    try {
      await widget.onSubmit(reason, details.isEmpty ? null : details);
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showErrorSnack(context, 'Your report was not sent. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AmberHeaderScaffold(
      backFallback: widget.backFallback,
      title: widget.title,
      subtitleWidget: widget.subtitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final reason in ReportReason.values) ...[
              ReportReasonRow(
                label: reason.label,
                selected: _reason == reason,
                onTap: _isSubmitting
                    ? null
                    : () => setState(() => _reason = reason),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 10),
            AppTextArea(
              label: 'Add details (optional)',
              controller: _detailsController,
              placeholder: 'Tell us what happened',
              minHeight: 72,
            ),
            if (widget.extra != null) ...[
              const SizedBox(height: 16),
              widget.extra!,
            ],
          ],
        ),
      ),
      bottomBar: Column(
        children: [
          AppPrimaryButton(
            label: 'Send report',
            isLoading: _isSubmitting,
            onPressed: _reason == null || _isSubmitting ? null : _submit,
          ),
          if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
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
        ],
      ),
    );
  }
}

/// One radio-style reason row (honey fill + 2px ink border when selected,
/// plus a filled radio icon so the choice is not shown by colour alone).
class ReportReasonRow extends StatelessWidget {
  const ReportReasonRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.honey : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: AppColors.ink, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
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

/// The shared "Report sent" result (screens 12 and 42).
class ReportSentView extends StatelessWidget {
  const ReportSentView({
    super.key,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryLoading = false,
  });

  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool secondaryLoading;

  @override
  Widget build(BuildContext context) {
    return CelebrationScreen(
      icon: Icons.check_rounded,
      title: 'Report sent',
      body: Text(message),
      actions: [
        AppPrimaryButton(label: primaryLabel, onPressed: onPrimary),
        if (secondaryLabel != null)
          AppSecondaryButton(
            label: secondaryLabel!,
            isLoading: secondaryLoading,
            onPressed: secondaryLoading ? null : onSecondary,
          ),
      ],
    );
  }
}
