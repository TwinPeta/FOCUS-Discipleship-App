import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

const String _marqueeText =
    'CONNECT   •   LEARN   •   GROW   •   SUCCEED   •   CONNECT   •   LEARN   •   ';

/// Slow looping marquee strip. Respects the platform's reduced-motion
/// accessibility setting by rendering a static line instead of animating.
class MarqueeStrip extends StatefulWidget {
  const MarqueeStrip({super.key});

  @override
  State<MarqueeStrip> createState() => _MarqueeStripState();
}

class _MarqueeStripState extends State<MarqueeStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _cachedWidth;
  TextStyle? _cachedStyle;
  TextScaler? _cachedScaler;

  /// Laid out once per style/scale, not on every build.
  double _textWidth(TextStyle style, TextScaler scaler) {
    if (_cachedWidth != null &&
        style == _cachedStyle &&
        scaler == _cachedScaler) {
      return _cachedWidth!;
    }
    final painter = TextPainter(
      text: TextSpan(text: _marqueeText, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    _cachedStyle = style;
    _cachedScaler = scaler;
    _cachedWidth = painter.width;
    painter.dispose();
    return _cachedWidth!;
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.sectionHeading.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w900,
    );
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    const decoration = BoxDecoration(
      color: AppColors.white,
      border: Border(bottom: BorderSide(color: AppColors.ink, width: 2.5)),
    );

    if (reduceMotion) {
      return Container(
        decoration: decoration,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          _marqueeText.trim(),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    }

    final textWidth = _textWidth(style, MediaQuery.textScalerOf(context));

    return Container(
      decoration: decoration,
      height: MediaQuery.textScalerOf(context).scale(style.fontSize!) * 1.6,
      child: ClipRect(
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          // Only the offset animates; the two Text widgets are built once.
          child: AnimatedBuilder(
            animation: _controller,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_marqueeText, style: style, maxLines: 1, softWrap: false),
                Text(_marqueeText, style: style, maxLines: 1, softWrap: false),
              ],
            ),
            builder: (context, row) => Transform.translate(
              offset: Offset(-_controller.value * textWidth, 0),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}
