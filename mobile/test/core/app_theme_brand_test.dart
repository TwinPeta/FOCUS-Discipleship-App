import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_colors.dart';
import 'package:focus_1/core/theme/app_text_styles.dart';
import 'package:focus_1/core/theme/app_theme.dart';

/// Brand rules: Bricolage Grotesque everywhere, headings 700+. Carebook
/// (2026-11-20): Material primary is the blue selected-state colour; gold
/// stays on call-to-action buttons via AppGradients.brand.
void main() {
  final themes = {'light': AppTheme.light(), 'dark': AppTheme.dark()};
  final palettes = {'light': AppPalette.light, 'dark': AppPalette.dark};

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    test('$name theme uses Bricolage Grotesque', () {
      final t = theme.textTheme;
      for (final style in [
        t.displayLarge,
        t.headlineMedium,
        t.titleLarge,
        t.bodyMedium,
        t.labelLarge,
      ]) {
        expect(style?.fontFamily, AppFonts.family);
      }
      expect(theme.colorScheme.primary, palettes[name]!.primary);
      // Text on the blue stays readable: white in light, dark in dark mode.
      final onLum = theme.colorScheme.onPrimary.computeLuminance();
      expect(name == 'light' ? onLum > 0.9 : onLum < 0.1, isTrue);
    });
  }

  test('dark theme is dark with light text', () {
    final theme = AppTheme.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor.computeLuminance(), lessThan(0.05));
    expect(
      theme.textTheme.bodyMedium?.color?.computeLuminance(),
      greaterThan(0.8),
    );
  });

  test('headings use Bricolage at weight 700 or more', () {
    final headings = [
      AppTextStyles.landingHeroHeadline,
      AppTextStyles.landingSectionH2,
      AppTextStyles.landingFinalCtaH2,
      AppTextStyles.hubUniversityTitle,
      AppTextStyles.profileName,
      AppTextStyles.joinFormTitle,
      AppTextStyles.detailTitle,
      AppTextStyles.sectionHeading,
      AppTextStyles.tabTitle,
      AppTextStyles.celebrationTitle,
      AppTextStyles.viewerTitle,
      AppTextStyles.amberHeaderTitle,
    ];
    for (final style in headings) {
      expect(style.fontFamily, AppFonts.family);
      expect(style.fontWeight!.value, greaterThanOrEqualTo(700));
      expect(style.fontWeight!.value, lessThanOrEqualTo(800));
    }
    expect(
      AppTextStyles.cardTitle.fontWeight!.value,
      inInclusiveRange(600, 700),
    );
    expect(AppTextStyles.body.fontWeight!.value, inInclusiveRange(400, 500));
  });
}
