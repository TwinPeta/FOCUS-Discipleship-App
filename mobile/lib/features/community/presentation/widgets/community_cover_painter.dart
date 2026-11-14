import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

/// Stylised "person" cover art: a cluster of circles plus a half-circle
/// "shoulders" shape, scaled from a 390-wide design canvas to the actual
/// cover width (section 6.4: "Draw it with CustomPaint scaled to width").
class CommunityCoverPainter extends CustomPainter {
  const CommunityCoverPainter();

  static const _designWidth = 390.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _designWidth;
    canvas.save();
    canvas.scale(scale);

    final amber = Paint()..color = AppColors.amber;
    final white = Paint()..color = AppColors.white;
    final cream = Paint()..color = AppColors.cream;

    canvas.drawCircle(const Offset(250, 120), 70, amber);
    canvas.drawCircle(const Offset(318, 96), 64, white);
    canvas.drawCircle(const Offset(372, 140), 52, cream);
    canvas.drawCircle(const Offset(318, 70), 14, amber);

    final shouldersPath = Path()
      ..moveTo(278, 160)
      ..arcToPoint(
        const Offset(358, 160),
        radius: const Radius.circular(40),
        clockwise: true,
      )
      ..lineTo(358, 190)
      ..lineTo(278, 190)
      ..close();
    canvas.drawPath(shouldersPath, amber);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CommunityCoverPainter oldDelegate) => false;
}
