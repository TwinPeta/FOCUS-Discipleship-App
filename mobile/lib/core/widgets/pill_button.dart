import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Compact pill action ("I prayed", "Respond"). Draws 36px tall but keeps a
/// 44px hit area.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: filled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? AppColors.amber : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: filled
                    ? null
                    : Border.all(color: AppColors.ink, width: 2),
              ),
              child: Text(
                label,
                style: AppTextStyles.chip.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
