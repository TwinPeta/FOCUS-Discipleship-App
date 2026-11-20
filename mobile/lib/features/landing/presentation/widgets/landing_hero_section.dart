import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'community_preview.dart';
import 'landing_pill_button.dart';

/// Landing hero (screen 1): brand gradient with rounded bottom corners,
/// logo + Sign in, headline, the two calls to action and a phone preview
/// of the General community.
class LandingHeroSection extends StatelessWidget {
  const LandingHeroSection({super.key, required this.onWatchStories});

  final VoidCallback onWatchStories;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.celebration,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 18,
        24,
        0,
      ),
      // Carebook: a blue circle peeks in at the top right, behind the logo
      // row's Sign in button.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -MediaQuery.paddingOf(context).top - 100,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LogoRow(),
              const SizedBox(height: 32),
              // One line each, as designed: shrink to the width rather than
              // breaking inside a word on small phones or with large text.
              // "Grow. Succeed." in blue, as designed.
              for (final (line, blue) in const [
                ('Find your people.', false),
                ('Grow. Succeed.', true),
              ])
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    line,
                    style: blue
                        ? AppTextStyles.landingHeroHeadline.copyWith(
                            color: AppColors.primary,
                          )
                        : AppTextStyles.landingHeroHeadline,
                    maxLines: 1,
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'Connect with students on your campus who share your values, learn '
                'together and build the future you want.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              LandingPillButton(
                label: 'Explore caregroups',
                trailingArrow: true,
                onPressed: () => context.push('/join/start'),
              ),
              const SizedBox(height: 12),
              _WatchStoriesLink(onTap: onWatchStories),
              const SizedBox(height: 28),
              const Center(child: CommunityPreview()),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoRow extends StatelessWidget {
  const _LogoRow();

  @override
  Widget build(BuildContext context) {
    // Keep the logo row on its two designed lines with large text.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
      ),
      child: _row(context),
    );
  }

  Widget _row(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'FCU',
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            textScaler: TextScaler.noScaling,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Fellowship of\nChristian Unions',
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 10),
        LandingPillButton(
          label: 'Sign in',
          height: 44,
          fontSize: 16,
          shadow: false,
          onPressed: () => context.push('/login'),
        ),
      ],
    );
  }
}

class _WatchStoriesLink extends StatelessWidget {
  const _WatchStoriesLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Watch student stories',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Watch student stories',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    color: AppColors.primary,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
