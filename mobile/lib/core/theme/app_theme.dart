import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.amber,
        primary: AppColors.amber,
        onPrimary: AppColors.ink,
        surface: AppColors.page,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.page,
      fontFamily: GoogleFonts.sourceSans3().fontFamily,
      splashFactory: InkRipple.splashFactory,
    );
    // Start from the theme's own text styles. An empty `TextTheme()` left
    // every style null, so text fields had no colour and typed text showed
    // white on white on some phones.
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: GoogleFonts.sourceSans3().fontFamily,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.honey,
        selectionHandleColor: AppColors.amber,
      ),
    );
  }
}
