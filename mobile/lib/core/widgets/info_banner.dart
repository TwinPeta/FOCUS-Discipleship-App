import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Cream banner with a leading icon, used for informational copy such as the
/// "only one specific community" rule.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.child,
    this.icon = Icons.info_outline_rounded,
    this.trailing,
  });

  final Widget child;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle(
              style: AppTextStyles.body.copyWith(fontSize: 13.5),
              child: child,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
