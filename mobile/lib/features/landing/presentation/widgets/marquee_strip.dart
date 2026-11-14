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

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.sectionHeading.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w900,
    );
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final decoration = const BoxDecoration(
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

    final textPainter = TextPainter(
      text: TextSpan(text: _marqueeText, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final textWidth = textPainter.width;

    return Container(
      decoration: decoration,
      height: style.fontSize! * 1.6,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final dx = -_controller.value * textWidth;
            return OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _marqueeText,
                      style: style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                    Text(
                      _marqueeText,
                      style: style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
