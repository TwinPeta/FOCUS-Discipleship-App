import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_gradients.dart';

/// Loading placeholder shared by every screen: an optional amber header
/// block, then two post-shaped white cards. Pulses its opacity (no
/// package) and holds still when the platform asks for reduced motion.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.showHeader = true, this.cardCount = 2});

  /// False inside shells that already draw their own amber header.
  final bool showHeader;
  final int cardCount;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) const _HeaderBlock(),
        for (var i = 0; i < widget.cardCount; i++)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _CardBlock(),
          ),
      ],
    );
    // Works in a bounded body (clips extra cards) and inside slivers or
    // other unbounded parents (sizes to its content).
    final content = LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? ClipRect(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: column,
              ),
            )
          : column,
    );
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: reduceMotion
            ? content
            : FadeTransition(opacity: _controller, child: content),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.headerBottom),
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        width: 160,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.width, this.height = 12, this.circle = false});

  final double? width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBlock,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(AppRadii.sm),
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Block(width: 40, height: 40, circle: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Block(width: (w - 50) * 0.5),
                        const SizedBox(height: 6),
                        _Block(width: (w - 50) * 0.3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Block(width: w),
              const SizedBox(height: 8),
              _Block(width: w * 0.8),
              const SizedBox(height: 12),
              _Block(width: w, height: 90),
            ],
          );
        },
      ),
    );
  }
}
