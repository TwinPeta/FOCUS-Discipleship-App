import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/filter_chips.dart';
import '../../../core/widgets/general_shell.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/membership.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/post.dart';
import 'widgets/compose_fab.dart';
import 'widgets/composer_row.dart';
import 'widgets/feed_list.dart';

/// Screen 8: the General feed, shared by everyone on campus.
class GeneralFeedScreen extends ConsumerWidget {
  const GeneralFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(generalCommunityProvider);

    return communityAsync.when(
      loading: () =>
          const Scaffold(backgroundColor: AppColors.page, body: Skeleton()),
      error: (error, stackTrace) =>
          ErrorScreen(onRetry: () => ref.invalidate(generalCommunityProvider)),
      data: (community) {
        final profile = ref.watch(currentProfileProvider);
        final membership =
            ref.watch(membershipProvider).valueOrNull ?? Membership.empty;
        final hasApprovedSpecific =
            membership.status == MembershipStatus.approved &&
            membership.communityId != null;
        void compose() => context.push('/general-feed/compose');

        return GeneralShell(
          floatingActionButton: ComposeFab(onPressed: compose),
          body: FeedList(
            feedKey: (communityId: community.id, scope: PostScope.general),
            onCompose: compose,
            header: [
              ComposerRow(
                initials: profile?.initials ?? 'Y',
                photoPath: profile?.photoPath,
                onTap: compose,
              ),
              _QuickLinks(
                circleId: hasApprovedSpecific ? membership.communityId : null,
              ),
              if (!hasApprovedSpecific) const _FindCommunityPromo(),
            ],
          ),
        );
      },
    );
  }
}

/// Home quick links: General · your circle · Prayer wall · Testimonies ·
/// Learn. The circle, Prayer wall and Testimonies links need an approved
/// specific community ([circleId]); Learn (General resources) does not.
class _QuickLinks extends ConsumerWidget {
  const _QuickLinks({required this.circleId});

  final String? circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = circleId;
    final circleName = circle == null
        ? null
        : ref.watch(communityByIdProvider(circle)).valueOrNull?.name;
    final links = <(String, String?)>[
      ('General', null),
      if (circle != null) ...[
        (circleName ?? 'My circle', '/community/$circle/feed'),
        ('Prayer wall', '/community/$circle/prayer'),
        ('Testimonies', '/community/$circle/testimonies'),
      ],
      ('Learn', '/general-feed/resources'),
    ];
    return FilterChips<String?>(
      options: [
        for (final (label, route) in links)
          FilterChipOption(label: label, value: route),
      ],
      // "General" (this screen) is the selected link.
      value: null,
      onChanged: (route) {
        if (route == null) return;
        // Scope switches replace the screen; Learn sits on top of it.
        if (route.startsWith('/general-feed/')) {
          context.push(route);
        } else {
          context.go(route);
        }
      },
    );
  }
}

class _FindCommunityPromo extends StatelessWidget {
  const _FindCommunityPromo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Want a mentor and a smaller group?',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 6),
          Text(
            'Join a specific community to meet in person and grow with your mentors.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          AppSecondaryButton(
            label: 'Find a specific community',
            height: 46,
            onPressed: () => context.push('/communities'),
          ),
        ],
      ),
    );
  }
}
