import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/post_photo_art.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/sized_file_image.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import 'providers/feed_providers.dart';

/// Screen 39: Post & comments (`/post/:id`).
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    try {
      await ref.read(postDetailProvider(widget.postId).notifier).toggleLike();
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not save your like.');
    }
  }

  Future<void> _submitComment() async {
    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    final text = _commentController.text.trim();
    if (!online || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _commentController.clear();
    try {
      await ref
          .read(postCommentsProvider(widget.postId).notifier)
          .addComment(text);
      if (mounted && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        if (_commentController.text.isEmpty) {
          _commentController.text = text;
        }
        showErrorSnack(context, 'Could not post your comment. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(postDetailProvider(widget.postId));
    ref.invalidate(postCommentsProvider(widget.postId));
    await Future.wait([
      ref.read(postDetailProvider(widget.postId).future),
      ref.read(postCommentsProvider(widget.postId).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    if (postAsync.isLoading && !postAsync.hasValue) {
      return const Scaffold(backgroundColor: AppColors.page, body: Skeleton());
    }
    if (postAsync.hasError && !postAsync.hasValue) {
      return ErrorScreen(
        onRetry: () => ref.invalidate(postDetailProvider(widget.postId)),
      );
    }

    final post = postAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        children: [
          _PostDetailTopBar(
            postId: widget.postId,
            showOptions: post != null,
          ),
          if (post == null)
            const Expanded(
              child: Center(
                child: EmptyState(
                  icon: Icons.article_outlined,
                  title: 'Post not available',
                  body:
                      'This post may have been removed or is from someone you blocked.',
                ),
              ),
            )
          else ...[
            const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _PostBodyCard(
                      post: post,
                      commentCount: commentsAsync.valueOrNull?.length ?? 0,
                      online: online,
                      onLikeTap: online ? _toggleLike : null,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text('Comments', style: AppTextStyles.sectionHeading),
                        const SizedBox(width: 8),
                        if (commentsAsync.hasValue)
                          Text(
                            '(${commentsAsync.value!.length})',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.inkDeemphasized80,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...commentsAsync.when(
                      loading: () => const [
                        Skeleton(showHeader: false, cardCount: 2),
                      ],
                      error: (_, _) => [
                        ErrorView(
                          onRetry: () =>
                              ref.invalidate(postCommentsProvider(widget.postId)),
                        ),
                      ],
                      data: (comments) {
                        if (comments.isEmpty) {
                          return [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.cardSmall,
                                ),
                                boxShadow: AppShadows.soft,
                              ),
                              child: Text(
                                'No comments yet. Start the conversation below.',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.inkDeemphasized80,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ];
                        }
                        return [
                          for (final comment in comments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CommentCard(
                                key: ValueKey(comment.id),
                                comment: comment,
                              ),
                            ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
            ),
            _CommentInputBar(
              controller: _commentController,
              online: online,
              isSending: _isSending,
              onSend: _submitComment,
            ),
          ],
        ],
      ),
    );
  }
}

class _PostDetailTopBar extends StatelessWidget {
  const _PostDetailTopBar({required this.postId, required this.showOptions});

  final String postId;
  final bool showOptions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.headerBottom),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              RoundIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/communities'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Post',
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showOptions)
                RoundIconButton(
                  icon: Icons.more_horiz_rounded,
                  semanticLabel: 'Post options',
                  onPressed: () => context.push('/post/$postId/options'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostBodyCard extends ConsumerWidget {
  const _PostBodyCard({
    required this.post,
    required this.commentCount,
    required this.online,
    required this.onLikeTap,
  });

  final Post post;
  final int commentCount;
  final bool online;
  final VoidCallback? onLikeTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String communityName;
    if (post.scope == PostScope.general) {
      communityName = 'General community';
    } else {
      communityName =
          ref.watch(communityByIdProvider(post.communityId)).valueOrNull?.name ??
          'Community';
    }

    final Widget? photoWidget = switch (post.photo) {
      null => null,
      PostPhoto(isArt: true) => const PostPhotoArt(),
      PostPhoto(:final path?) => Image(
        image: sizedFileImage(
          context,
          path,
          logicalSize: MediaQuery.sizeOf(context).width,
        ),
        fit: BoxFit.cover,
      ),
      PostPhoto() => null,
    };

    final likeWord = post.likeCount == 1 ? 'like' : 'likes';
    final commentWord = commentCount == 1 ? 'comment' : 'comments';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: "View ${post.author.name}'s profile",
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: () => context.push('/members/${post.author.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AvatarWithPresence(
                      initials: post.author.initials,
                      size: 44,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                post.author.name,
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              if (post.roleLabel != null)
                                RoleBadge(label: post.roleLabel!),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatRelativeTime(post.createdAt)} · $communityName',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12.5,
                              color: AppColors.inkDeemphasized80,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (photoWidget != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: photoWidget,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            post.body,
            style: AppTextStyles.body.copyWith(fontSize: 16, height: 1.5),
          ),
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                height: 140,
                width: double.infinity,
                color: AppColors.cream,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: AppColors.placeholder,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.cream)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  '${post.likeCount} $likeWord · $commentCount $commentWord',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.inkDeemphasized80,
                  ),
                ),
                PillButton(
                  label: post.likedByMe ? 'Liked' : 'Like',
                  semanticLabel: online
                      ? (post.likedByMe
                            ? 'Liked. ${post.likeCount} $likeWord'
                            : 'Like post. ${post.likeCount} $likeWord')
                      : 'Like disabled while offline',
                  filled: post.likedByMe,
                  onTap: onLikeTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: "View ${comment.author.name}'s profile",
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/members/${comment.author.id}'),
              child: AvatarWithPresence(
                initials: comment.author.initials,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/members/${comment.author.id}'),
                  child: Text(
                    '${comment.author.name} · ${formatRelativeTime(comment.createdAt)}',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: AppTextStyles.body.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.online,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool online;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cream, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!online)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Comments are paused while offline.',
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.placeholder,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: online,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Write a comment',
                      hintStyle: const TextStyle(color: AppColors.placeholder),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: online ? AppColors.page : AppColors.cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.ink,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final canSend =
                        online && !isSending && value.text.trim().isNotEmpty;
                    return Semantics(
                      button: true,
                      enabled: canSend,
                      label: online
                          ? 'Send comment'
                          : 'Send comment disabled while offline',
                      child: InkWell(
                        onTap: canSend ? onSend : null,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: canSend
                                ? AppColors.amber
                                : AppColors.amber.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.ink,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: AppColors.ink,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
