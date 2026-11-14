import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.amber,
        primary: AppColors.amber,
        onPrimary: AppColors.ink,
        surface: AppColors.page,
      ),
      scaffoldBackgroundColor: AppColors.page,
      fontFamily: GoogleFonts.sourceSans3().fontFamily,
      splashFactory: InkRipple.splashFactory,
    ).copyWith(
      textTheme: const TextTheme().apply(
        fontFamily: GoogleFonts.sourceSans3().fontFamily,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
