import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// The two shadow styles used across the design: a hard, zero-blur offset
/// shadow for the landing page's "bold" style, and a soft blurred shadow for
/// feed cards in the "soft" style used by every other screen.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> hard({Offset offset = const Offset(4, 4)}) => [
    BoxShadow(color: AppColors.ink, offset: offset, blurRadius: 0),
  ];

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.10),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];
}
