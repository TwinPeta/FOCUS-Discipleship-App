import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The phone at the bottom of the landing hero: a sketch of the General
/// community feed (title, tabs, composer, two posts), cut off by the
/// hero's edge. Purely decorative.
class CommunityPreview extends StatelessWidget {
  const CommunityPreview({super.key});

  static const width = 252.0;
  static const visibleHeight = 300.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: visibleHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: 420,
            child: Container(
              width: width,
              height: 420,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.18),
                    offset: const Offset(0, -6),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.page,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: MediaQuery.withNoTextScaling(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'General community',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            _dot(16, AppColors.cream),
                            const SizedBox(width: 4),
                            _dot(16, AppColors.cream),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            _bar(46, 18, gradient: AppGradients.brand),
                            const SizedBox(width: 4),
                            _bar(52, 18, color: AppColors.white),
                            const SizedBox(width: 4),
                            _bar(44, 18, color: AppColors.white),
                          ],
                        ),
                        const SizedBox(height: 7),
                        _card(
                          padding: 6,
                          child: Row(
                            children: [
                              _dot(18, AppColors.honey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.inputBorder,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        _post(),
                        const SizedBox(height: 7),
                        _post(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _dot(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  static Widget _bar(
    double width,
    double height, {
    Color? color,
    Gradient? gradient,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      gradient: gradient,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );

  static Widget _line(double fraction, double height, Color color) =>
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction,
        child: _bar(double.infinity, height, color: color),
      );

  static Widget _card({required double padding, required Widget child}) =>
      Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.10),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: child,
      );

  static Widget _post() => _card(
    padding: 8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _dot(20, AppColors.honey),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _line(0.45, 7, AppColors.inputBorder),
                  const SizedBox(height: 3),
                  _line(0.25, 7, AppColors.skeletonBlock),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _line(0.8, 9, AppColors.ink),
        const SizedBox(height: 6),
        _line(0.95, 7, AppColors.skeletonBlock),
        const SizedBox(height: 6),
        _line(0.7, 7, AppColors.skeletonBlock),
        const SizedBox(height: 6),
        Row(
          children: [
            _bar(34, 14, color: AppColors.honey),
            const SizedBox(width: 5),
            _bar(34, 14, color: AppColors.cream),
          ],
        ),
      ],
    ),
  );
}
