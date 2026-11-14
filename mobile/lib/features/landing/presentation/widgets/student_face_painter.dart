import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

/// A simple cartoon student: head circle, shoulders, smile. Flat [fillColor]
/// fill with 3px ink outlines, matching the landing illustration style.
class StudentFacePainter extends CustomPainter {
  const StudentFacePainter({required this.fillColor});

  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height * 0.4);
    final headRadius = size.width * 0.26;

    final shoulderWidth = size.width * 0.82;
    final shoulderHeight = size.height * 0.4;
    final shoulderRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.92),
      width: shoulderWidth,
      height: shoulderHeight,
    );
    final shoulderPath = Path()
      ..moveTo(shoulderRect.left, shoulderRect.bottom)
      ..lineTo(shoulderRect.left, shoulderRect.center.dy)
      ..arcToPoint(
        Offset(shoulderRect.right, shoulderRect.center.dy),
        radius: Radius.circular(shoulderWidth / 2),
        clockwise: true,
      )
      ..lineTo(shoulderRect.right, shoulderRect.bottom)
      ..close();
    canvas.drawPath(shoulderPath, fill);
    canvas.drawPath(shoulderPath, stroke);

    canvas.drawCircle(center, headRadius, fill);
    canvas.drawCircle(center, headRadius, stroke);

    final eyePaint = Paint()..color = AppColors.ink;
    final eyeOffsetX = headRadius * 0.4;
    final eyeOffsetY = headRadius * 0.05;
    final eyeRadius = headRadius * 0.08;
    canvas.drawCircle(
      Offset(center.dx - eyeOffsetX, center.dy - eyeOffsetY),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + eyeOffsetX, center.dy - eyeOffsetY),
      eyeRadius,
      eyePaint,
    );

    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + headRadius * 0.25),
      width: headRadius * 0.9,
      height: headRadius * 0.7,
    );
    canvas.drawArc(smileRect, 0.15, 2.85, false, stroke);
  }

  @override
  bool shouldRepaint(covariant StudentFacePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor;
  }
}
