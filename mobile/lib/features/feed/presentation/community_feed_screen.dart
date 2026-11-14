import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/post_card.dart';
import '../../profile/presentation/profile_providers.dart';
import 'providers/feed_providers.dart';
import 'widgets/composer_row.dart';

/// The "Feed" tab inside [CommunityShell] for a specific community.
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final postsAsync = ref.watch(feedPostsProvider(communityId));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () =>
              ref.read(feedPostsProvider(communityId).notifier).refresh(),
          child: postsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                      '/compose?scope=specific',
                      extra: {'communityId': communityId},
                    ),
                  ),
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
                            .read(feedPostsProvider(communityId).notifier)
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
        Positioned(
          right: 16,
          bottom: 16,
          child: _ComposeFab(
            onPressed: () => context.push(
              '/compose?scope=specific',
              extra: {'communityId': communityId},
            ),
          ),
        ),
      ],
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
