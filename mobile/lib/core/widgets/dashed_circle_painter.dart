import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Dashed circle outline, used for "add a photo" and locked-badge rings.
class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter({
    this.color,
    this.strokeWidth = 2,
    this.dashCount = 28,
  });

  final Color? color;

  /// [color], or the theme's ink.
  Color get _color => color ?? AppColors.ink;
  final double strokeWidth;
  final int dashCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final radius = size.width / 2;
    const gapFraction = 0.5;
    final circumference = 2 * 3.1415926535 * radius;
    final dashLength = circumference / dashCount * (1 - gapFraction);
    final path = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - 1),
      );
    final metrics = path.computeMetrics().first;
    var distance = 0.0;
    while (distance < metrics.length) {
      canvas.drawPath(
        metrics.extractPath(distance, distance + dashLength),
        paint,
      );
      distance += circumference / dashCount;
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) {
    return oldDelegate.color != _color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashCount != dashCount;
  }
}
