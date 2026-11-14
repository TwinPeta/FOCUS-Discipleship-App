import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

/// White, bordered, hard-shadow button used in the landing page's bold style.
class BoldButton extends StatelessWidget {
  const BoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 62,
    this.backgroundColor = AppColors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.ink, width: 2.5),
            boxShadow: AppShadows.hard(),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
