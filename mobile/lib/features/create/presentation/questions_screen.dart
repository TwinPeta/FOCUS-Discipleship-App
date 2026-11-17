import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_bottom_nav.dart' show approvedCommunityId;
import '../../../core/widgets/community_header_chrome.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/membership.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../feed/domain/post.dart';
import '../../feed/presentation/providers/feed_providers.dart';
import '../../feed/presentation/question_screens.dart';

/// "Pass" choices made in this session, by question id (true = passed,
/// false = undone). The server keeps them ([Post.passedByMe]); this only
/// makes a tap take effect before the feed reloads.
final passedQuestionsProvider =
    NotifierProvider<PassedQuestions, Map<String, bool>>(PassedQuestions.new);

class PassedQuestions extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  /// Whether [question] is passed, counting choices not yet reloaded.
  bool isPassed(Post question) => state[question.id] ?? question.passedByMe;

  /// Passes on [id] (or undoes it with [passed] false) on the server. The
  /// choice shows at once and is reverted if the server refuses it.
  Future<void> set(String id, {required bool passed}) async {
    final before = state;
    state = {...state, id: passed};
    try {
      await ref.read(postRepositoryProvider).setPassed(id, passed: passed);
    } catch (_) {
      state = before;
      rethrow;
    }
  }
}

enum _Where { all, general, mine }

/// Screen 67: "Questions for you" (`/questions`): questions from the
/// General community and the member's own one, unanswered first. Which
/// ones show is picked from "⋯".
class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({super.key});

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  _Where _where = _Where.all;

  @override
  Widget build(BuildContext context) {
    final general = ref.watch(generalCommunityProvider).valueOrNull;
    final mine = approvedCommunityId(
      ref.watch(membershipProvider).valueOrNull ?? Membership.empty,
    );
    final mineName = mine == null
        ? null
        : ref.watch(communityByIdProvider(mine)).valueOrNull?.name;
    final keys = <FeedKey>[
      if (general != null && _where != _Where.mine)
        (communityId: general.id, scope: PostScope.general),
      if (mine != null && _where != _Where.general)
        (communityId: mine, scope: PostScope.specific),
    ];
    final feeds = [for (final k in keys) ref.watch(feedPostsProvider(k))];
    ref.watch(passedQuestionsProvider);
    final passed = ref.read(passedQuestionsProvider.notifier);
    final loading =
        (keys.isEmpty && _where == _Where.all) ||
        feeds.any((f) => f.isLoading && !f.hasValue);
    final questions =
        [
          for (final f in feeds)
            ...?f.valueOrNull?.where(
              (p) => p.kind == PostKind.question && !passed.isPassed(p),
            ),
        ]..sort((a, b) {
          // Unanswered first, then newest.
          final byAnswers = (a.commentCount == 0 ? 0 : 1).compareTo(
            b.commentCount == 0 ? 0 : 1,
          );
          return byAnswers != 0
              ? byAnswers
              : b.createdAt.compareTo(a.createdAt);
        });

    String label(_Where w) => switch (w) {
      _Where.all => 'All',
      _Where.general => 'General',
      _Where.mine => mineName ?? 'My community',
    };

    return AmberHeaderScaffold(
      title: 'Questions for you',
      subtitle: _where == _Where.all
          ? 'People in your community are waiting for an answer.'
          : label(_where),
      backFallback: '/general-feed',
      headerAction: RoundIconButton(
        icon: Icons.more_horiz_rounded,
        semanticLabel: 'Show',
        onPressed: () => showSectionMenu(context, 'Questions', [
          for (final w in _Where.values)
            if (w != _Where.mine || mine != null)
              SectionMenuItem(
                label: label(w),
                icon: switch (w) {
                  _Where.all => Icons.forum_outlined,
                  _Where.general => Icons.public_rounded,
                  _Where.mine => Icons.groups_outlined,
                },
                active: w == _where,
                onSelected: () => setState(() => _where = w),
              ),
        ]),
      ),
      body: loading
          ? const Skeleton(showHeader: false)
          : questions.isEmpty
          ? EmptyState(
              icon: Icons.question_answer_outlined,
              title: 'No questions waiting',
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
                return _QuestionCard(
                  key: ValueKey(q.id),
                  question: q,
                  place: q.scope == PostScope.general
                      ? 'General community'
                      : (mineName ?? 'Your community'),
                  onPass: () {
                    final messenger = ScaffoldMessenger.of(context);
                    Future<void> choose({required bool passed}) => ref
                        .read(passedQuestionsProvider.notifier)
                        .set(q.id, passed: passed)
                        .catchError((Object _) {
                          if (context.mounted) showErrorSnack(context);
                        });
                    choose(passed: true);
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: const Text('Question hidden'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () => choose(passed: false),
                          ),
                        ),
                      );
                  },
                );
              },
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.place,
    required this.onPass,
  });

  final Post question;
  final String place;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.cardSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        onTap: () => context.push('/post/${question.id}'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.body,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 16,
                  height: 1.35,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                [
                  answersLabel(question.commentCount),
                  place,
                  formatRelativeTime(question.createdAt),
                ].join(' · '),
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  color: AppColors.inkDeemphasized80,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push(answerRoute(question.id)),
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
                  TextButton(
                    onPressed: onPass,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Text(
                      'Pass',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
