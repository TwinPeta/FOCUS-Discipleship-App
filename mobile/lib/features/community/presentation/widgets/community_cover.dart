import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../domain/community.dart';
import 'community_cover_painter.dart';
import '../../../../core/theme/app_gradients.dart';

/// The detail screen's 200px cover: vector art background, a back button,
/// and a bottom-overlapping identity card.
class CommunityCover extends StatelessWidget {
  const CommunityCover({
    super.key,
    required this.community,
    required this.institutionName,
  });

  final Community community;
  final String institutionName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRect(
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Container(
              color: AppColors.honey,
              child: const RepaintBoundary(
                child: CustomPaint(
                  painter: CommunityCoverPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: RoundIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/communities'),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -28,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    community.initials,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        community.name,
                        style: AppTextStyles.detailTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$institutionName · Specific community',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12.5,
                          color: AppColors.inkDeemphasized80,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
