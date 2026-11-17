import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Letter-spacing in the design is specified in em; this converts it to
/// logical px for [TextStyle.letterSpacing] (em * fontSize).
double _em(double em, double fontSize) => em * fontSize;

/// Bricolage Grotesque is bundled in `assets/fonts/` and declared in
/// pubspec.yaml (roadmap v2 brand rules). The family ships 400-800, so
/// headings use 800 at most.
class AppFonts {
  AppFonts._();

  static const family = 'BricolageGrotesque';
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacingEm = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: AppFonts.family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: _em(letterSpacingEm, size),
      color: color ?? AppColors.ink,
    );
  }

  static TextStyle get landingHeroHeadline => _base(
    size: 56,
    weight: FontWeight.w800,
    height: 0.94,
    letterSpacingEm: -0.035,
  );

  static TextStyle get landingSectionH2 => _base(
    size: 38,
    weight: FontWeight.w800,
    height: 1.0,
    letterSpacingEm: -0.03,
  );

  static TextStyle get landingFinalCtaH2 =>
      _base(size: 40, weight: FontWeight.w800, height: 0.98);

  static TextStyle get hubUniversityTitle => _base(
    size: 32,
    weight: FontWeight.w800,
    height: 1.02,
    letterSpacingEm: -0.02,
  );

  static TextStyle get profileName => _base(size: 28, weight: FontWeight.w800);

  static TextStyle get joinFormTitle => _base(
    size: 28,
    weight: FontWeight.w800,
    height: 1.1,
    letterSpacingEm: -0.02,
  );

  static TextStyle get detailTitle => _base(size: 26, weight: FontWeight.w800);

  static TextStyle get sectionHeading =>
      _base(size: 20, weight: FontWeight.w800);

  /// Big title at the top of a community tab (Prayer wall, Testimonies).
  static TextStyle get tabTitle => _base(size: 24, weight: FontWeight.w800);

  /// Result screens (request approved, badge earned, report sent).
  static TextStyle get celebrationTitle =>
      _base(size: 34, weight: FontWeight.w800, height: 1.05);

  /// Title of a learning viewer (video, devotional, quiz, document).
  static TextStyle get viewerTitle =>
      _base(size: 28, weight: FontWeight.w800, height: 1.1);

  static TextStyle get cardTitle => _base(size: 17, weight: FontWeight.w700);

  static TextStyle get body =>
      _base(size: 15, weight: FontWeight.w400, height: 1.45);

  static TextStyle get bodyMedium =>
      _base(size: 15, weight: FontWeight.w500, height: 1.45);

  static TextStyle get fieldLabel => _base(size: 12, weight: FontWeight.w700);

  static TextStyle get chip => _base(size: 12, weight: FontWeight.w700);

  static TextStyle get eyebrow =>
      _base(size: 13, weight: FontWeight.w800, letterSpacingEm: 0.08);

  static TextStyle get amberHeaderTitle => _base(
    size: 30,
    weight: FontWeight.w800,
    height: 1.05,
    letterSpacingEm: -0.6 / 30,
  );

  static TextStyle get amberHeaderSubtitle =>
      _base(size: 16, weight: FontWeight.w500);
}
