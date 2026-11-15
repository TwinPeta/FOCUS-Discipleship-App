import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Dark-mode surfaces (roadmap A0.3): near-black page, slightly lifted
/// cards and sheets, light text, amber kept for accents.
class _Dark {
  static const page = Color(0xFF0F0F0F);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceHigh = Color(0xFF242424);
  static const outline = Color(0xFF3A3A3A);
  static const text = Color(0xFFF2F2F2);
  static const textMuted = Color(0xFFB8B8B8);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.amberLight,
        primary: AppColors.amberLight,
        onPrimary: AppColors.ink,
        secondary: AppColors.amberDark,
        onSecondary: AppColors.ink,
        surface: AppColors.page,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.page,
      fontFamily: AppFonts.family,
      splashFactory: InkRipple.splashFactory,
    );
    // Start from the theme's own text styles. An empty `TextTheme()` left
    // every style null, so text fields had no colour and typed text showed
    // white on white on some phones.
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.ink),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.honey,
        selectionHandleColor: AppColors.amberLight,
      ),
    );
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.amberLight,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.amberLight,
          onPrimary: AppColors.ink,
          secondary: AppColors.amberDark,
          onSecondary: AppColors.ink,
          surface: _Dark.surface,
          onSurface: _Dark.text,
          onSurfaceVariant: _Dark.textMuted,
          surfaceContainerLowest: _Dark.page,
          surfaceContainerLow: _Dark.surface,
          surfaceContainer: _Dark.surface,
          surfaceContainerHigh: _Dark.surfaceHigh,
          surfaceContainerHighest: _Dark.surfaceHigh,
          outline: _Dark.outline,
          outlineVariant: _Dark.outline,
          error: AppColors.error,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _Dark.page,
      canvasColor: _Dark.page,
      cardColor: _Dark.surface,
      dividerColor: _Dark.outline,
      fontFamily: AppFonts.family,
      splashFactory: InkRipple.splashFactory,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _Dark.outline),
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, _Dark.text),
      iconTheme: const IconThemeData(color: _Dark.text),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.amberLight,
        selectionColor: AppColors.amberDark.withValues(alpha: 0.4),
        selectionHandleColor: AppColors.amberLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _Dark.page,
        foregroundColor: _Dark.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(color: _Dark.surface, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _Dark.surfaceHigh,
        hintStyle: const TextStyle(color: _Dark.textMuted),
        labelStyle: const TextStyle(color: _Dark.textMuted),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.amberLight, width: 2),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _Dark.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _Dark.text,
        ),
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15,
          color: _Dark.text,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _Dark.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _Dark.surfaceHigh,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          color: _Dark.text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _Dark.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.amberDark,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : _Dark.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.amberLight
                : _Dark.textMuted,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _Dark.surface,
        selectedItemColor: AppColors.amberLight,
        unselectedItemColor: _Dark.textMuted,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color color) => base.apply(
    fontFamily: AppFonts.family,
    bodyColor: color,
    displayColor: color,
  );
}
