import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'bold_style.dart';
import 'student_face_painter.dart';

const double _designWidth = 342;
const double _designHeight = 290;

double _deg(double degrees) => degrees * math.pi / 180;

/// The hero's tilted-card collage of three cartoon students with sticker
/// pills, sized to the 342x290 design artboard and scaled down to fit
/// narrower screens.
class IllustrationCollage extends StatelessWidget {
  const IllustrationCollage({super.key, required this.onPlayTap});

  final VoidCallback onPlayTap;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: _designWidth,
        height: _designHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 58,
              child: Transform.rotate(
                angle: _deg(-6),
                child: const _StudentCard(
                  width: 122,
                  height: 160,
                  color: AppColors.cream,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 38,
              child: Transform.rotate(
                angle: _deg(5),
                child: const _StudentCard(
                  width: 122,
                  height: 160,
                  color: AppColors.white,
                ),
              ),
            ),
            Positioned(
              left: (_designWidth - 170) / 2,
              top: 14,
              child: Transform.rotate(
                angle: _deg(2),
                child: _StudentCard(
                  width: 170,
                  height: 230,
                  color: AppColors.honey,
                  playButtonOnTap: onPlayTap,
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 2,
              child: Transform.rotate(
                angle: _deg(-8),
                child: const _StickerPill(label: 'Connect'),
              ),
            ),
            Positioned(
              right: 6,
              top: 2,
              child: Transform.rotate(
                angle: _deg(7),
                child: const _StickerPill(label: 'Learn'),
              ),
            ),
            Positioned(
              left: _designWidth / 2 - 46,
              bottom: 0,
              child: Transform.rotate(
                angle: _deg(-3),
                child: const _StickerPill(label: 'Succeed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.width,
    required this.height,
    required this.color,
    this.playButtonOnTap,
  });

  final double width;
  final double height;
  final Color color;
  final VoidCallback? playButtonOnTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: boldCardDecoration(color: color, radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(width, height),
                painter: const StudentFacePainter(fillColor: AppColors.amber),
              ),
            ),
          ),
          if (playButtonOnTap != null)
            Semantics(
              button: true,
              label: 'Play student stories video',
              child: GestureDetector(
                onTap: playButtonOnTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.ink,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StickerPill extends StatelessWidget {
  const _StickerPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: AppShadows.hard(offset: const Offset(2, 2)),
      ),
      child: Text(label, style: AppTextStyles.chip.copyWith(fontSize: 13)),
    );
  }
}
