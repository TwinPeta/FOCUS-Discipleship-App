import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/bold_button.dart';
import 'bold_style.dart';
import 'illustration_collage.dart';
import '../../../../core/config/landing_videos.dart';
import '../../../../core/utils/open_link.dart';

class LandingHeroSection extends StatelessWidget {
  const LandingHeroSection({super.key, required this.onWatchStories});

  final VoidCallback onWatchStories;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.amber,
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 2.5)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogoRow(),
          const SizedBox(height: 18),
          _Headline(),
          const SizedBox(height: 18),
          Text(
            'Connect with students on your campus who share your values, learn '
            'together and build the future you want.',
            style: AppTextStyles.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: IllustrationCollage(
              onPlayTap: () => openVideo(
                context,
                LandingVideos.featured.url,
                title: LandingVideos.featured.title,
              ),
            ),
          ),
          const SizedBox(height: 18),
          BoldButton(
            label: 'Explore communities ->',
            height: 62,
            onPressed: () => context.push('/join'),
          ),
          const SizedBox(height: 18),
          Center(
            child: Semantics(
              button: true,
              label: 'Watch student stories',
              child: InkWell(
                onTap: onWatchStories,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Watch student stories',
                        style: AppTextStyles.bodyMedium.copyWith(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            'FCU',
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Fellowship of\nChristian Unions',
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const _SignInPill(),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Find your people.', style: AppTextStyles.landingHeroHeadline),
        Text('Grow.', style: AppTextStyles.landingHeroHeadline),
        Transform.rotate(
          angle: -2 * math.pi / 180,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Text('Succeed.', style: AppTextStyles.landingHeroHeadline),
          ),
        ),
      ],
    );
  }
}

/// White bold-style pill opening sign in (built in prompt 2).
class _SignInPill extends StatelessWidget {
  const _SignInPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Sign in',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/login'),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: boldCardDecoration(
              color: AppColors.white,
              radius: AppRadii.pill,
              shadowOffset: const Offset(2, 2),
            ),
            child: Text(
              'Sign in',
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
