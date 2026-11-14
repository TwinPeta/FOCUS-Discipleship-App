import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Small pill used for day/time, room, and role badges.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.honey,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.ink),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTextStyles.chip),
        ],
      ),
    );
  }
}
