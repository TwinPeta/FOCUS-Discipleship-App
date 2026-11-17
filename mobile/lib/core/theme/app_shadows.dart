import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// The two shadow styles used across the design: a hard, zero-blur offset
/// shadow for the landing page's "bold" style, and a soft blurred shadow for
/// feed cards in the "soft" style used by every other screen.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> hard({Offset offset = const Offset(4, 4)}) => [
    BoxShadow(color: AppColors.shadow, offset: offset, blurRadius: 0),
  ];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.10),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Lifted soft shadow for the landing page's cards and white pills
  /// (design: `0 8px 24px rgba(17,17,17,.10)`).
  static List<BoxShadow> get lifted => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.10),
      offset: const Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}
