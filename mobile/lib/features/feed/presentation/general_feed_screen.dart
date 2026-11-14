import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/general_shell.dart';
import '../../../core/widgets/post_card.dart';
import '../../community/domain/membership.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../profile/presentation/profile_providers.dart';
import 'providers/feed_providers.dart';
import 'widgets/composer_row.dart';

/// Screen 8: the General feed, shared by everyone on campus.
class GeneralFeedScreen extends ConsumerWidget {
  const GeneralFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(generalCommunityProvider);

    return communityAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.page,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.page,
        body: Center(
          child: Text(
            'Could not load the General feed.',
            style: AppTextStyles.body,
          ),
        ),
      ),
      data: (community) {
        final profile = ref.watch(currentProfileProvider);
        final membership = ref.watch(membershipProvider).valueOrNull ?? Membership.empty;
        final hasApprovedSpecific =
            membership.status == MembershipStatus.approved &&
            membership.communityId != null;
        final postsAsync = ref.watch(feedPostsProvider(community.id));

        return GeneralShell(
          floatingActionButton: _ComposeFab(
            onPressed: () => context.push(
              '/compose?scope=general',
              extra: {'communityId': community.id},
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                ref.read(feedPostsProvider(community.id).notifier).refresh(),
            child: postsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Could not load the feed.',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
              data: (posts) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    ComposerRow(
                      initials: profile?.initials ?? 'Y',
                      photoPath: profile?.photoPath,
                      onTap: () => context.push(
                        '/compose?scope=general',
                        extra: {'communityId': community.id},
                      ),
                    ),
                    if (!hasApprovedSpecific) ...[
                      const SizedBox(height: 12),
                      const _FindCommunityPromo(),
                    ],
                    const SizedBox(height: 12),
                    if (posts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            'No posts yet. Be the first to share something.',
                            style: AppTextStyles.body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < posts.length; i++) ...[
                        PostCard(
                          authorName: posts[i].author.name,
                          authorInitials: posts[i].author.initials,
                          timestamp: formatRelativeTime(posts[i].createdAt),
                          body: posts[i].body,
                          roleBadgeLabel: posts[i].roleLabel,
                          media: posts[i].media,
                          showActions: posts[i].roleLabel != null,
                          liked: posts[i].likedByMe,
                          likeCount: posts[i].likeCount,
                          onLikeTap: () => ref
                              .read(feedPostsProvider(community.id).notifier)
                              .toggleLike(posts[i].id),
                          onCommentTap: () => ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text('Comments coming soon'),
                            ),
                          ),
                        ),
                        if (i != posts.length - 1) const SizedBox(height: 12),
                      ],
                  ],
                );
              },
            ),
          ),
        );
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

class _ComposeFab extends StatelessWidget {
  const _ComposeFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New post',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.amber,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2.5),
              boxShadow: AppShadows.hard(offset: const Offset(3, 3)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: AppColors.ink, size: 28),
          ),
        ),
      ),
    );
  }
}
