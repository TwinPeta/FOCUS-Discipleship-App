import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Shared gradients (roadmap v2). Use [brand] for headers and primary
/// buttons; use [AppColors.amberDark] alone for emphasis.
class AppGradients {
  AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.amberLight, AppColors.amberDark],
  );
}
