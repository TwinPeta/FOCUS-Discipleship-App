import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';

/// Shared "bold style" card decoration used throughout the landing page:
/// a 2.5px ink border and a hard, zero-blur offset shadow.
BoxDecoration boldCardDecoration({
  required Color color,
  required double radius,
  double borderWidth = 2.5,
  Offset shadowOffset = const Offset(4, 4),
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.ink, width: borderWidth),
    boxShadow: AppShadows.hard(offset: shadowOffset),
  );
}
