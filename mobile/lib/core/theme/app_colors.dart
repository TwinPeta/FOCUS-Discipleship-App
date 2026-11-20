import 'package:flutter/widgets.dart';

/// One set of app colours. [light] is the design; [dark] is the same roles
/// for dark mode (brand gold deepened so light text stays readable on it).
class AppPalette {
  const AppPalette({
    required this.amberLight,
    required this.amberDark,
    required this.honey,
    required this.cream,
    required this.page,
    required this.white,
    required this.ink,
    required this.inputBorder,
    required this.placeholder,
    required this.skeletonBlock,
    required this.inkDeemphasized85,
    required this.inkDeemphasized80,
    required this.primary,
    required this.primarySoft,
    required this.muted,
  });

  final Color amberLight;
  final Color amberDark;
  final Color honey;
  final Color cream;
  final Color page;
  final Color white;
  final Color ink;
  final Color inputBorder;
  final Color placeholder;
  final Color skeletonBlock;
  final Color inkDeemphasized85;
  final Color inkDeemphasized80;

  /// Carebook blue: selected tabs and chips, links, progress, checkboxes.
  final Color primary;

  /// Pale blue fill: info banners, icon tiles, avatars.
  final Color primarySoft;

  /// Secondary text (meta lines, captions).
  final Color muted;

  static const light = AppPalette(
    // Carebook prototype (2026-11-20): gold call-to-action gradient,
    // navy text, cream page, blue for selected states.
    amberLight: Color(0xFFFFCB3D),
    amberDark: Color(0xFFEE9A00),
    honey: Color(0xFFFDE68A),
    cream: Color(0xFFFFF1D4),
    page: Color(0xFFFFFAF2),
    white: Color(0xFFFFFFFF),
    ink: Color(0xFF1F2D3D),
    inputBorder: Color(0xFFCFE0F3),
    placeholder: Color(0xFF6A6A6A),
    skeletonBlock: Color(0xFFEEEDE8),
    inkDeemphasized85: Color(0xD91F2D3D),
    inkDeemphasized80: Color(0xFF5B6B7D),
    primary: Color(0xFF1E6AB8),
    primarySoft: Color(0xFFE3F0FD),
    muted: Color(0xFF6B7C90),
  );

  static const dark = AppPalette(
    amberLight: Color(0xFF9A7608),
    amberDark: Color(0xFF6E5403),
    honey: Color(0xFF3A3112),
    cream: Color(0xFF2A2412),
    page: Color(0xFF12110D),
    white: Color(0xFF1E1C17),
    ink: Color(0xFFF2EFE6),
    inputBorder: Color(0xFF4A4232),
    placeholder: Color(0xFFADA89C),
    skeletonBlock: Color(0xFF2A2822),
    inkDeemphasized85: Color(0xD9F2EFE6),
    inkDeemphasized80: Color(0xCCF2EFE6),
    primary: Color(0xFF6AA8EE),
    primarySoft: Color(0xFF1C2B3C),
    muted: Color(0xFFA9B4C2),
  );
}

/// The app's colours. Each role follows the current theme (see
/// [usePalette], set by the app root when Light / Dark / System changes);
/// only [error] and [success] are fixed.
class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.light;

  /// Whether the dark palette is in use.
  static bool get isDark => identical(_p, AppPalette.dark);

  /// Switches every colour role. The app root rebuilds the screen after.
  static void usePalette({required bool dark}) =>
      _p = dark ? AppPalette.dark : AppPalette.light;

  /// Flat brand amber where a gradient cannot be drawn (painted art,
  /// switch tracks, thin accents); equals the gradient's light end.
  /// Fills use `AppGradients.brand`.
  static Color get amber => _p.amberLight;

  /// Brand gradient (roadmap v2): the light end is the normal surface
  /// (headers, primary buttons, chips); the dark end is for emphasis only
  /// (active tab, selected state, key call to action, badges).
  static Color get amberLight => _p.amberLight;
  static Color get amberDark => _p.amberDark;
  static Color get honey => _p.honey;
  static Color get cream => _p.cream;
  static Color get page => _p.page;

  /// Card / sheet surface (white in the light theme).
  static Color get white => _p.white;

  /// Main text and icons.
  static Color get ink => _p.ink;
  static Color get inputBorder => _p.inputBorder;
  static Color get placeholder => _p.placeholder;
  static Color get skeletonBlock => _p.skeletonBlock;
  static Color get inkDeemphasized85 => _p.inkDeemphasized85;
  static Color get inkDeemphasized80 => _p.inkDeemphasized80;
  static Color get primary => _p.primary;
  static Color get primarySoft => _p.primarySoft;
  static Color get muted => _p.muted;

  /// Text and icons on [primary] / [AppGradients.primary].
  static const onPrimary = Color(0xFFFFFFFF);

  /// Shadows stay dark in both themes.
  static const shadow = Color(0xFF000000);

  static const error = Color(0xFFF44336);
  static const success = Color(0xFF4CAF50);
}
