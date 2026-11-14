import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Letter-spacing in the design is specified in em; this converts it to
/// logical px for [TextStyle.letterSpacing] (em * fontSize).
double _em(double em, double fontSize) => em * fontSize;

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacingEm = 0,
    Color color = AppColors.ink,
  }) {
    return GoogleFonts.sourceSans3(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: _em(letterSpacingEm, size),
      color: color,
    );
  }

  static TextStyle landingHeroHeadline = _base(
    size: 56,
    weight: FontWeight.w900,
    height: 0.94,
    letterSpacingEm: -0.035,
  );

  static TextStyle landingSectionH2 = _base(
    size: 38,
    weight: FontWeight.w900,
    height: 1.0,
    letterSpacingEm: -0.03,
  );

  static TextStyle landingFinalCtaH2 = _base(
    size: 40,
    weight: FontWeight.w900,
    height: 0.98,
  );

  static TextStyle hubUniversityTitle = _base(
    size: 32,
    weight: FontWeight.w900,
    height: 1.02,
    letterSpacingEm: -0.02,
  );

  static TextStyle profileName = _base(size: 28, weight: FontWeight.w900);

  static TextStyle joinFormTitle = _base(
    size: 28,
    weight: FontWeight.w900,
    height: 1.1,
    letterSpacingEm: -0.02,
  );

  static TextStyle detailTitle = _base(size: 26, weight: FontWeight.w900);

  static TextStyle sectionHeading = _base(size: 20, weight: FontWeight.w900);

  static TextStyle cardTitle = _base(size: 17, weight: FontWeight.w800);

  static TextStyle body = _base(
    size: 15,
    weight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle bodyMedium = _base(
    size: 15,
    weight: FontWeight.w500,
    height: 1.45,
  );

  static TextStyle fieldLabel = _base(size: 12, weight: FontWeight.w700);

  static TextStyle chip = _base(size: 12, weight: FontWeight.w700);

  static TextStyle eyebrow = _base(
    size: 13,
    weight: FontWeight.w800,
    letterSpacingEm: 0.08,
  );

  static TextStyle amberHeaderTitle = _base(
    size: 30,
    weight: FontWeight.w900,
    height: 1.05,
    letterSpacingEm: -0.6 / 30,
  );

  static TextStyle amberHeaderSubtitle = _base(size: 16, weight: FontWeight.w500);
}
