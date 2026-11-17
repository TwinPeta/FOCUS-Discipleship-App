import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';

/// White pill on the amber gradient (landing design): "Explore
/// communities" and "Sign in". Soft shadow, no border.
class LandingPillButton extends StatelessWidget {
  const LandingPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 58,
    this.fontSize = 20,
    this.trailingArrow = false,
    this.expand = false,
    this.shadow = true,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;
  final double fontSize;
  final bool trailingArrow;

  /// Full width (final call to action) instead of hugging the label.
  final bool expand;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.pill);
    final text = Text(
      label,
      style: AppTextStyles.cardTitle.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
      maxLines: 1,
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: radius,
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.18),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: fontSize >= 18 ? 28 : 20,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shrink a long label rather than cutting it off.
                  Flexible(
                    child: FittedBox(fit: BoxFit.scaleDown, child: text),
                  ),
                  if (trailingArrow) ...[
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 22,
                      color: AppColors.ink,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
