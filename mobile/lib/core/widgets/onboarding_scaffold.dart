import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'round_icon_button.dart';
import 'step_progress.dart';

/// White sign-up/sign-in page: back button, optional "Step N of 3" bar,
/// title + subtitle, scrollable body and a pinned bottom action.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.step,
    required this.body,
    this.bottom,
    this.onBack,
    this.header,
  });

  final String title;

  /// Plain or rich subtitle.
  final Widget? subtitle;

  /// 1..3 shows the step bar; null hides it.
  final int? step;
  final Widget body;
  final Widget? bottom;
  final VoidCallback? onBack;

  /// Shown above the title (e.g. the FCU logo block on Sign in).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          // Full width, so Back stays on the left even without the step bar.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Back',
                    backgroundColor: AppColors.cream,
                    onPressed:
                        onBack ??
                        () =>
                            context.canPop() ? context.pop() : context.go('/'),
                  ),
                  if (step != null) ...[
                    const SizedBox(height: 12),
                    StepProgress(currentStep: step!),
                    const SizedBox(height: 6),
                    Text(
                      'Step $step of 3',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (header != null) ...[
                      header!,
                      const SizedBox(height: 20),
                    ],
                    Semantics(
                      header: true,
                      child: Text(title, style: AppTextStyles.joinFormTitle),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      DefaultTextStyle.merge(
                        style: AppTextStyles.body,
                        child: subtitle!,
                      ),
                    ],
                    const SizedBox(height: 24),
                    body,
                  ],
                ),
              ),
            ),
            if (bottom != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.cream)),
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}
