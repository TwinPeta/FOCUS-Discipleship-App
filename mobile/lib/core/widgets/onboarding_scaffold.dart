import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
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
    this.xp,
    this.xpReward,
  });

  /// Points earned so far in sign-up (the gold pill, top right).
  final int? xp;

  /// Points for finishing this step ("+10 XP when you continue").
  final int? xpReward;

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
      backgroundColor: AppColors.page,
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
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Back',
                        backgroundColor: AppColors.white,
                        onPressed:
                            onBack ??
                            () => context.canPop()
                                ? context.pop()
                                : context.go('/'),
                      ),
                      const Spacer(),
                      if (xp != null) XpPill(label: '$xp XP'),
                    ],
                  ),
                  if (step != null) ...[
                    const SizedBox(height: 12),
                    StepProgress(currentStep: step!),
                    const SizedBox(height: 6),
                    Text(
                      'STEP $step OF 3',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
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
                decoration: BoxDecoration(color: AppColors.page),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (xpReward != null) ...[
                      Center(
                        child: XpPill(
                          label: '+$xpReward XP when you continue',
                          soft: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    bottom!,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Points for the sign-up steps (Carebook): details +10, password +10,
/// email +10, rules +20. Shown only; the total is the Newcomer reward.
const signUpXpTotal = 50;

/// Gold star pill: "20 XP" (solid) or "+10 XP when you continue" (soft).
class XpPill extends StatelessWidget {
  const XpPill({super.key, required this.label, this.soft = false});

  final String label;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: soft ? AppColors.honey : null,
        gradient: soft ? null : AppGradients.brand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, size: 16, color: AppColors.ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.chip.copyWith(
                fontSize: soft ? 12 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
