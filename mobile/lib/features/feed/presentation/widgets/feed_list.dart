import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/error_snack.dart';
import '../../../../core/widgets/post_card.dart';
import '../../../../core/widgets/states/empty_state.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/saved_content_note.dart';
import '../../../../core/widgets/states/skeleton.dart';
import '../../domain/post.dart';
import '../providers/feed_providers.dart';
import 'post_options_sheet.dart';
import 'post_photo_view.dart';

/// The post list shared by the General and specific-community feeds:
/// virtualized, pull-to-refresh, loads the next page near the end.
class FeedList extends ConsumerWidget {
  const FeedList({
    super.key,
    required this.feedKey,
    required this.header,
    required this.onCompose,
  });

  final FeedKey feedKey;

  /// Rows shown above the posts (composer row, promo card…).
  final List<Widget> header;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider(feedKey));
    final controller = ref.read(feedPostsProvider(feedKey).notifier);

    if (postsAsync.isLoading && !postsAsync.hasValue) {
      return const Skeleton(showHeader: false);
    }
    if (postsAsync.hasError && !postsAsync.hasValue) {
      return ErrorView(
        onRetry: () => ref.invalidate(feedPostsProvider(feedKey)),
      );
    }

    final posts = postsAsync.valueOrNull ?? const <Post>[];
    final hasMore = controller.hasMore;
    final bodyCount = posts.isEmpty ? 1 : posts.length;
    // The Saved marker only exists offline, so the online layout is
    // unchanged.
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final rows = [...header, if (!online) const SavedContentNote()];
    final itemCount = rows.length + bodyCount + (hasMore ? 1 : 0);

    Future<void> onRefresh() async {
      try {
        await controller.refresh();
      } catch (_) {
        if (context.mounted) showErrorSnack(context);
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < rows.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: rows[index],
            );
          }
          final i = index - rows.length;
          if (posts.isEmpty && i == 0) {
            return EmptyState(
              icon: Icons.forum_outlined,
              title: 'No posts yet',
              body: 'Be the first to share something.',
              actionLabel: 'Write a post',
              onAction: onCompose,
            );
          }
          if (i >= posts.length) {
            controller.loadMore();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = posts[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(
              key: ValueKey(post.id),
              authorName: post.author.name,
              authorInitials: post.author.initials,
              timestamp: formatRelativeTime(post.createdAt),
              body: post.body,
              roleBadgeLabel: post.roleLabel,
              media: post.media,
              photo: postPhotoView(context, post.photo),
              onOpen: () => context.push('/post/${post.id}'),
              onMore: () => showPostOptionsSheet(context, post),
              liked: post.likedByMe,
              likeCount: post.likeCount,
              onLikeTap: () async {
                try {
                  await controller.toggleLike(post.id);
                } catch (_) {
                  if (context.mounted) {
                    showErrorSnack(context, 'Could not save your like.');
                  }
                }
              },
              commentCount: post.commentCount,
              onCommentTap: () => context.push('/post/${post.id}'),
            ),
          );
        },
      ),
    );
  }
}
