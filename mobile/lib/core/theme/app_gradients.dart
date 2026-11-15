import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Shared gradients (roadmap v2). Use [brand] for headers, cards, buttons
/// and selected states; use [AppColors.amberDark] alone for emphasis.
class AppGradients {
  AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.amberLight, AppColors.amberDark],
  );

  /// [brand] when [on] (e.g. a selected chip), otherwise none, so the
  /// decoration's `color` shows instead.
  static Gradient? when(bool on) => on ? brand : null;

  /// For `ElevatedButton.styleFrom(backgroundBuilder: ...)`: paints the
  /// brand gradient behind the button's label within [radius]; disabled
  /// buttons get a faded flat amber.
  static Widget Function(BuildContext, Set<WidgetState>, Widget?)
  buttonBackground(BorderRadius radius) => (context, states, child) {
    final disabled = states.contains(WidgetState.disabled);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: disabled ? null : brand,
        color: disabled ? AppColors.amberLight.withValues(alpha: 0.4) : null,
      ),
      child: child,
    );
  };
}
