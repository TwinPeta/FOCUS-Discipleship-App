import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Shared gradients (roadmap v2). Use [brand] for headers, cards, buttons
/// and selected states; use [AppColors.amberDark] alone for emphasis.
/// Follows the current theme like [AppColors].
class AppGradients {
  AppGradients._();

  static const _light = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFCB3D), Color(0xFFF4B400), Color(0xFFEE9A00)],
    stops: [0, 0.55, 1],
  );

  static const _dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9A7608), Color(0xFF6E5403)],
  );

  static LinearGradient get brand => AppColors.isDark ? _dark : _light;

  static const _primaryLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E6AB8), Color(0xFF2A74C0), Color(0xFF4C98E6)],
    stops: [0, 0.45, 1],
  );

  static const _primaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E5A9A), Color(0xFF2A6CB0)],
  );

  /// Blue: selected chips and tabs, the active nav item, progress.
  static LinearGradient get primary =>
      AppColors.isDark ? _primaryDark : _primaryLight;

  /// [primary] when [on], otherwise none.
  static Gradient? selected(bool on) => on ? primary : null;

  static const _pageHeaderLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC9E0F9), Color(0xFFE6F1FC), Color(0xFFFFE9A8)],
    stops: [0, 0.5, 1],
  );

  static const _pageHeaderDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2B3C), Color(0xFF22272E), Color(0xFF2A2412)],
  );

  static const _hubHeaderLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEDB0), Color(0xFFFFD25E), Color(0xFFF5B72E)],
    stops: [0, 0.55, 1],
  );

  /// Caregroups hub and My profile header: soft gold.
  static LinearGradient get hubHeader =>
      AppColors.isDark ? _dark : _hubHeaderLight;

  static const _celebrationLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE9A8), Color(0xFFFFD25E), Color(0xFFF4B400)],
    stops: [0, 0.5, 1],
  );

  /// Celebration screens (badge earned, joined): gold top area.
  static LinearGradient get celebration =>
      AppColors.isDark ? _dark : _celebrationLight;

  /// Sub-page header (Settings, Help, Messages...): blue to soft yellow.
  static LinearGradient get pageHeader =>
      AppColors.isDark ? _pageHeaderDark : _pageHeaderLight;

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
