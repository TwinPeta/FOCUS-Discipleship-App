import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Dashed rounded-rectangle outline, used for the hub/profile "no specific
/// community yet" slots. Flutter's [BorderStyle] has no dashed option, so
/// this paints the outline manually.
class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.radius,
    this.color,
    this.strokeWidth = 2,
  });

  final double radius;
  final Color? color;

  /// [color], or the theme's ink.
  Color get _color => color ?? AppColors.ink;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashGap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.color != _color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
