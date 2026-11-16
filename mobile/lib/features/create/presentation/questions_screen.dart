import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_bottom_nav.dart' show approvedCommunityId;
import '../../../core/widgets/post_card.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/membership.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../feed/domain/post.dart';
import '../../feed/presentation/providers/feed_providers.dart';

/// "Answer a question" (`/questions`): the questions asked in the General
/// community and in the student's own community, unanswered first. Opening
/// one lets you answer in its comments.
class QuestionsScreen extends ConsumerWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final general = ref.watch(generalCommunityProvider).valueOrNull;
    final mine = approvedCommunityId(
      ref.watch(membershipProvider).valueOrNull ?? Membership.empty,
    );
    final keys = <FeedKey>[
      if (general != null) (communityId: general.id, scope: PostScope.general),
      if (mine != null) (communityId: mine, scope: PostScope.specific),
    ];
    final feeds = [for (final k in keys) ref.watch(feedPostsProvider(k))];
    final loading =
        keys.isEmpty || feeds.any((f) => f.isLoading && !f.hasValue);
    final questions =
        [
          for (final f in feeds)
            ...?f.valueOrNull?.where((p) => p.kind == PostKind.question),
        ]..sort((a, b) {
          // Unanswered first, then newest.
          final byAnswers = (a.commentCount == 0 ? 0 : 1).compareTo(
            b.commentCount == 0 ? 0 : 1,
          );
          return byAnswers != 0
              ? byAnswers
              : b.createdAt.compareTo(a.createdAt);
        });

    return AmberHeaderScaffold(
      title: 'Answer a question',
      subtitle: 'Help someone in your community',
      body: loading
          ? const Skeleton(showHeader: false)
          : questions.isEmpty
          ? EmptyState(
              icon: Icons.question_answer_outlined,
              title: 'No questions yet',
              body: 'Questions people ask will appear here.',
              actionLabel: 'Ask a question',
              onAction: () => context.push('/create?type=question'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: questions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final q = questions[i];
                return PostCard(
                  key: ValueKey(q.id),
                  authorName: q.displayName,
                  authorInitials: q.displayInitials,
                  timestamp:
                      '${formatRelativeTime(q.createdAt)} · '
                      '${q.scope == PostScope.general ? 'General' : 'Your community'}',
                  body: q.body,
                  kindLabel: q.commentCount == 0
                      ? 'Question · no answers yet'
                      : 'Question',
                  showActions: true,
                  likeCount: q.likeCount,
                  liked: q.likedByMe,
                  commentCount: q.commentCount,
                  onOpen: () => context.push('/post/${q.id}'),
                  onCommentTap: () => context.push('/post/${q.id}'),
                );
              },
            ),
    );
  }
}
