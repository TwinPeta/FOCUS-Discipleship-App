import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/router/navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/report_icon_button.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/person.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../messaging/domain/report.dart';
import '../../messaging/presentation/content_report_screens.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import 'providers/post_detail_providers.dart';
import 'widgets/post_photo_view.dart';

/// Where "Answer" opens the full-screen answer (screen 65).
String answerRoute(String postId) => '/post/$postId/answer';

/// "General community" or the community's name.
String? _placeOf(WidgetRef ref, Post q) => q.scope == PostScope.general
    ? 'General community'
    : ref.watch(communityByIdProvider(q.communityId)).valueOrNull?.name;

String answersLabel(int n) => switch (n) {
  0 => 'No answers yet',
  1 => '1 answer',
  _ => '$n answers',
};

/// Screen 64: a question and its answers. Mentors' answers come first so
/// a newcomer sees the most trusted help at the top.
class QuestionBody extends ConsumerWidget {
  const QuestionBody({super.key, required this.question});

  final Post question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answersAsync = ref.watch(postCommentsProvider(question.id));
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final me = ref.watch(currentProfileProvider)?.id;
    final photo = postPhotoView(context, question.photo);
    final answers = [...?answersAsync.valueOrNull]
      ..sort((a, b) {
        final byRole = (a.author.role == PersonRole.member ? 1 : 0).compareTo(
          b.author.role == PersonRole.member ? 1 : 0,
        );
        if (byRole != 0) return byRole;
        final byVotes = b.voteCount.compareTo(a.voteCount);
        return byVotes != 0 ? byVotes : a.createdAt.compareTo(b.createdAt);
      });
    final count = answersAsync.hasValue
        ? answers.length
        : question.commentCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const OfflineBanner(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.body,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 19,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  'Asked by ${question.displayName}',
                  formatRelativeTime(question.createdAt),
                  ?_placeOf(ref, question),
                ].join(' · '),
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: AppColors.inkDeemphasized80,
                ),
              ),
              if (photo != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: photo,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: online
                        ? () => context.push(answerRoute(question.id))
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(44, 44),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Answer',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FollowButton(question: question, online: online),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                [
                  answersLabel(count),
                  if (question.followerCount > 0)
                    question.followerCount == 1
                        ? '1 follower'
                        : '${question.followerCount} followers',
                ].join(' · '),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Answers', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 10),
        if (answersAsync.isLoading && !answersAsync.hasValue)
          const Skeleton(showHeader: false, cardCount: 1)
        else if (answersAsync.hasError && !answersAsync.hasValue)
          ErrorView(
            title: 'Answers did not load',
            onRetry: () => ref.invalidate(postCommentsProvider(question.id)),
          )
        else if (answers.isEmpty)
          Text(
            'No answers yet. Be the first to help.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.inkDeemphasized80,
            ),
          )
        else
          for (final a in answers)
            _AnswerCard(
              answer: a,
              mine: a.author.id == me,
              online: online,
              onVote: () async {
                try {
                  await ref
                      .read(postCommentsProvider(question.id).notifier)
                      .toggleVote(a.id);
                } catch (_) {
                  if (context.mounted) {
                    showErrorSnack(context, 'Could not save your vote.');
                  }
                }
              },
              place: _placeOf(ref, question),
              onReport: a.author.id == me
                  ? null
                  : () => context.push(
                      contentReportLocation(
                        type: ReportTargetType.comment,
                        id: a.id,
                        authorId: a.author.id,
                        authorName: a.author.name,
                        communityId: question.communityId,
                        preview: a.text,
                        back: '/post/${question.id}',
                      ),
                    ),
            ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.mine,
    required this.online,
    required this.onVote,
    required this.place,
    required this.onReport,
  });

  final Comment answer;
  final bool mine;
  final bool online;
  final VoidCallback onVote;
  final String? place;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final leader = answer.author.role != PersonRole.member;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          border: leader
              ? Border.all(color: AppColors.amber, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push('/members/${answer.author.id}'),
                  child: AvatarWithPresence(
                    initials: answer.author.initials,
                    size: 40,
                  ),
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
                            answer.author.name,
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          if (leader)
                            RoleBadge(label: answer.author.role.label),
                        ],
                      ),
                      Text(
                        formatRelativeTime(answer.createdAt),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.inkDeemphasized80,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onReport != null)
                  ReportIconButton(
                    label: 'Report answer',
                    onPressed: onReport!,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                answer.text,
                style: AppTextStyles.body.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 6),
            _HelpfulButton(
              count: answer.voteCount,
              voted: answer.votedByMe,
              // Not on your own answer; not offline.
              onTap: mine || !online ? null : onVote,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom of the question page: opens the full answer screen.
class WriteAnswerBar extends ConsumerWidget {
  const WriteAnswerBar({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        color: AppColors.white,
        child: Material(
          color: AppColors.page,
          shape: StadiumBorder(
            side: BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: online ? () => context.push(answerRoute(questionId)) : null,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              child: Text(
                online ? 'Write an answer…' : 'You are offline',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.placeholder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 65: write an answer, full screen (`/post/:id/answer`).
class WriteAnswerScreen extends ConsumerStatefulWidget {
  const WriteAnswerScreen({super.key, required this.questionId});

  final String questionId;

  @override
  ConsumerState<WriteAnswerScreen> createState() => _WriteAnswerScreenState();
}

class _WriteAnswerScreenState extends ConsumerState<WriteAnswerScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(postCommentsProvider(widget.questionId).notifier)
          .add(text);
      if (!mounted) return;
      popOr(context, '/post/${widget.questionId}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showErrorSnack(context, 'Your answer was not posted. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(postDetailProvider(widget.questionId));
    final me = ref.watch(currentProfileProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final canPost = online && !_sending && _text.text.trim().isNotEmpty;
    final q = question.valueOrNull;

    return AmberHeaderScaffold(
      title: 'Answer',
      backFallback: '/post/${widget.questionId}',
      headerAction: FilledButton(
        onPressed: canPost ? _post : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.page,
          disabledBackgroundColor: AppColors.white,
          disabledForegroundColor: AppColors.placeholder,
          minimumSize: const Size(72, 44),
          shape: const StadiumBorder(),
        ),
        child: _sending
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.page,
                ),
              )
            : const Text('Post', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: switch (question) {
        AsyncValue(isLoading: true, hasValue: false) => const Skeleton(
          showHeader: false,
          cardCount: 1,
        ),
        _ when q == null => const EmptyState(
          icon: Icons.help_outline_rounded,
          title: 'Question not available',
          body: 'This question was removed or is no longer visible to you.',
        ),
        _ => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const OfflineBanner(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                border: Border(
                  left: BorderSide(color: AppColors.amber, width: 4),
                ),
              ),
              child: Text(
                q.body,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                AvatarWithPresence(
                  initials: initialsOf(me?.fullName ?? ''),
                  size: 40,
                ),
                const SizedBox(width: 10),
                Text(
                  me?.fullName ?? 'You',
                  style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Your answer', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 6),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 6,
              maxLines: 14,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write your answer',
                helperText: 'Be kind and helpful',
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.question, required this.online});

  final Post question;
  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = question.following;
    return Semantics(
      toggled: following,
      child: OutlinedButton.icon(
        onPressed: online
            ? () async {
                try {
                  await ref
                      .read(postDetailProvider(question.id).notifier)
                      .toggleFollow();
                } catch (_) {
                  if (context.mounted) {
                    showErrorSnack(context, 'Could not save. Try again.');
                  }
                }
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: following ? AppColors.honey : null,
          side: BorderSide(color: AppColors.inputBorder, width: 1.5),
          minimumSize: const Size(44, 44),
          shape: const StadiumBorder(),
        ),
        icon: Icon(
          following
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          size: 18,
        ),
        label: Text(
          following ? 'Following' : 'Follow',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// "Helpful · n" on an answer: one vote per member, not on your own.
class _HelpfulButton extends StatelessWidget {
  const _HelpfulButton({
    required this.count,
    required this.voted,
    required this.onTap,
  });

  final int count;
  final bool voted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: voted,
      enabled: onTap != null,
      label: voted
          ? 'You found this helpful. $count in all'
          : 'Mark as helpful. $count so far',
      excludeSemantics: true,
      child: Material(
        color: voted ? AppColors.honey : AppColors.cream,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    voted ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                    size: 16,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    count == 0 ? 'Helpful' : 'Helpful · $count',
                    style: AppTextStyles.chip.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
