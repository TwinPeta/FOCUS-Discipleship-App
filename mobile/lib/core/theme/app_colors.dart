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

  static const light = AppPalette(
    amberLight: Color(0xFFF5CE3E),
    amberDark: Color(0xFFE5A90A),
    honey: Color(0xFFFDE68A),
    cream: Color(0xFFFFF3C4),
    page: Color(0xFFFFFBEA),
    white: Color(0xFFFFFFFF),
    ink: Color(0xFF111111),
    inputBorder: Color(0xFFE6D48A),
    placeholder: Color(0xFF6A6A6A),
    skeletonBlock: Color(0xFFEEEDE8),
    inkDeemphasized85: Color(0xD9111111),
    inkDeemphasized80: Color(0xCC111111),
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

  /// Shadows stay dark in both themes.
  static const shadow = Color(0xFF000000);

  static const error = Color(0xFFF44336);
  static const success = Color(0xFF4CAF50);
}
