import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/message_input_bar.dart';
import '../../../core/widgets/post_card.dart';
import '../../../core/widgets/report_icon_button.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../messaging/domain/report.dart';
import '../../messaging/presentation/content_report_screens.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import 'providers/feed_providers.dart';
import 'providers/post_detail_providers.dart';
import 'question_screens.dart';
import 'widgets/post_options_sheet.dart';
import 'widgets/post_photo_view.dart';

/// Screen 39: Post & comments (`/post/:id`).
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    try {
      await ref.read(postCommentsProvider(widget.postId).notifier).add(text);
    } catch (_) {
      if (!mounted) return;
      // Give the text back so nothing typed is lost.
      if (_commentController.text.isEmpty) _commentController.text = text;
      showErrorSnack(context, 'Your comment was not sent. Please try again.');
    }
  }

  Future<void> _toggleLike() async {
    try {
      await ref.read(postDetailProvider(widget.postId).notifier).toggleLike();
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not save your like.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final post = postAsync.valueOrNull;
    final question = post?.kind == PostKind.question;

    return AmberHeaderScaffold(
      backFallback: post == null ? '/communities' : feedRouteFor(post),
      title: question ? 'Question' : 'Post',
      headerAction: post == null
          ? null
          : RoundIconButton(
              icon: Icons.more_horiz_rounded,
              semanticLabel: 'Post options',
              onPressed: () =>
                  showPostOptionsSheet(context, post, onDetail: true),
            ),
      body: switch (postAsync) {
        AsyncValue(isLoading: true, hasValue: false) => const Skeleton(
          showHeader: false,
          cardCount: 1,
        ),
        AsyncValue(hasError: true, hasValue: false) => ErrorView(
          onRetry: () => ref.invalidate(postDetailProvider(widget.postId)),
        ),
        _ when post == null => const EmptyState(
          icon: Icons.forum_outlined,
          title: 'Post not available',
          body: 'This post was removed or is no longer visible to you.',
        ),
        _ when question => QuestionBody(question: post),
        _ => _PostBody(post: post, online: online, onLike: _toggleLike),
      },
      bottomBar: post == null
          ? null
          : question
          ? WriteAnswerBar(questionId: post.id)
          : MessageInputBar(
              controller: _commentController,
              onSend: _sendComment,
              hintText: online
                  ? 'Write a comment'
                  : 'Write a comment (sent when back online)',
              sendLabel: 'Send comment',
            ),
    );
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({
    required this.post,
    required this.online,
    required this.onLike,
  });

  final Post post;
  final bool online;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(postCommentsProvider(post.id));
    final communityName = post.scope == PostScope.general
        ? 'General caregroup'
        : ref.watch(communityByIdProvider(post.communityId)).valueOrNull?.name;
    final photo = postPhotoView(context, post.photo);
    final comments = commentsAsync.valueOrNull ?? const <Comment>[];
    final me = ref.watch(currentProfileProvider)?.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const OfflineBanner(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthorRow(
                post: post,
                subtitle: [
                  formatRelativeTime(post.createdAt),
                  ?communityName,
                ].join(' · '),
              ),
              const SizedBox(height: 12),
              Text(post.body, style: AppTextStyles.body.copyWith(height: 1.5)),
              if (photo != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  image: true,
                  label: 'Post photo',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: photo,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 18,
                children: [
                  PostActionButton.like(
                    liked: post.likedByMe,
                    count: post.likeCount,
                    onTap: onLike,
                  ),
                  PostActionButton.comment(count: post.commentCount),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Comments', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 10),
        if (commentsAsync.isLoading && !commentsAsync.hasValue)
          const Skeleton(showHeader: false, cardCount: 1)
        else if (commentsAsync.hasError && !commentsAsync.hasValue)
          ErrorView(
            title: 'Comments did not load',
            onRetry: () => ref.invalidate(postCommentsProvider(post.id)),
          )
        else if (comments.isEmpty)
          Text(
            'No comments yet. Be the first to say something kind.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.inkDeemphasized80,
            ),
          )
        else
          for (final comment in comments)
            _CommentRow(
              comment: comment,
              onReport: comment.author.id == me
                  ? null
                  : () => context.push(
                      contentReportLocation(
                        type: ReportTargetType.comment,
                        id: comment.id,
                        authorId: comment.author.id,
                        authorName: comment.author.name,
                        communityId: post.communityId,
                        preview: comment.text,
                        back: feedRouteFor(post),
                      ),
                    ),
            ),
      ],
    );
  }
}

void _openMember(BuildContext context, String id) =>
    context.push('/members/$id');

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post, required this.subtitle});

  final Post post;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: !post.anonymous,
            label: post.anonymous
                ? 'Posted anonymously'
                : 'View ${post.author.name}\'s profile',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              // Anonymous: no profile to open.
              onTap: post.anonymous
                  ? null
                  : () => _openMember(context, post.author.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    AvatarWithPresence(
                      initials: post.displayInitials,
                      size: 44,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.displayName,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: AppColors.inkDeemphasized80,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (post.roleLabel != null) ...[
          const SizedBox(width: 8),
          Flexible(child: RoleBadge(label: post.roleLabel!)),
        ],
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment, required this.onReport});

  final Comment comment;

  /// Null on the user's own comments.
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'View ${comment.author.name}\'s profile',
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _openMember(context, comment.author.id),
              child: AvatarWithPresence(
                initials: comment.author.initials,
                size: 44,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.cardSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: comment.author.name,
                                style: AppTextStyles.fieldLabel.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' · ${formatRelativeTime(comment.createdAt)}',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 12,
                                  color: AppColors.inkDeemphasized80,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (onReport != null)
                        ReportIconButton(
                          label: 'Report comment',
                          onPressed: onReport!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: AppTextStyles.body.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
