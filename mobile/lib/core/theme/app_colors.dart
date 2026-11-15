import 'package:flutter/widgets.dart';

class AppColors {
  AppColors._();

  /// Flat brand amber where a gradient cannot be drawn (painted art,
  /// switch tracks, thin accents); equals the gradient's light end.
  /// Fills use [AppGradients.brand].
  static const amber = amberLight;

  /// Brand gradient (roadmap v2): the light end is the normal surface
  /// (headers, primary buttons, chips); the dark end is for emphasis only
  /// (active tab, selected state, key call to action, badges).
  static const amberLight = Color(0xFFF5CE3E);
  static const amberDark = Color(0xFFE5A90A);
  static const honey = Color(0xFFFDE68A);
  static const cream = Color(0xFFFFF3C4);
  static const page = Color(0xFFFFFBEA);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111111);
  static const inputBorder = Color(0xFFE6D48A);
  static const placeholder = Color(0xFF6A6A6A);
  static const error = Color(0xFFF44336);
  static const success = Color(0xFF4CAF50);
  static const skeletonBlock = Color(0xFFEEEDE8);

  static const inkDeemphasized85 = Color(0xD9111111);
  static const inkDeemphasized80 = Color(0xCC111111);
}
