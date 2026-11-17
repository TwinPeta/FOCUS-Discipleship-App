import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Vector placeholder "photo" for seeded posts (no bitmaps in the repo):
/// a campus sunrise in the app palette.
class PostPhotoArt extends StatelessWidget {
  const PostPhotoArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(painter: _SunrisePainter(), size: Size.infinite),
    );
  }
}

class _SunrisePainter extends CustomPainter {
  const _SunrisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cream, AppColors.honey],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(w * 0.7, h * 0.55),
      h * 0.28,
      Paint()..color = AppColors.amber,
    );
    final far = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.3, h * 0.5, w * 0.6, h * 0.7)
      ..quadraticBezierTo(w * 0.85, h * 0.82, w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      far,
      Paint()..color = AppColors.amber.withValues(alpha: 0.6),
    );
    final near = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.45, h * 0.7, w, h * 0.9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(near, Paint()..color = AppColors.ink);
    // A small chapel silhouette on the near hill.
    final chapel = Path()
      ..moveTo(w * 0.2, h * 0.82)
      ..lineTo(w * 0.2, h * 0.68)
      ..lineTo(w * 0.24, h * 0.6)
      ..lineTo(w * 0.28, h * 0.68)
      ..lineTo(w * 0.28, h * 0.8)
      ..close();
    canvas.drawPath(chapel, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
