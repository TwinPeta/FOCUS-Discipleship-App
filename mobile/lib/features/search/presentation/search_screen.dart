import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/community.dart';
import '../../../core/utils/date_utils.dart';
import '../../community/domain/member_profile.dart';
import '../../feed/domain/post.dart';
import '../domain/search_results.dart';
import 'search_providers.dart';

/// Screen 62: search communities and people, with session recents.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static const debounce = Duration(milliseconds: 300);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _gap = 12.0;
  static const _minTarget = 44.0;

  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(SearchScreen.debounce, () => _commit(value));
  }

  void _commit(String value) {
    if (!mounted) return;
    setState(() => _query = value.trim());
  }

  void _useRecent(String q) {
    _debounce?.cancel();
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _commit(q);
  }

  void _remember() => ref.read(recentSearchesProvider.notifier).add(_query);

  void _openCommunity(Community c) {
    _remember();
    context.push(
      c.type == CommunityType.general
          ? '/general-feed'
          : '/communities/${c.id}',
    );
  }

  void _openPerson(MemberProfile m) {
    _remember();
    context.push('/members/${m.person.id}');
  }

  void _openPost(Post p) {
    _remember();
    context.push('/post/${p.id}');
  }

  @override
  Widget build(BuildContext context) {
    return AmberHeaderScaffold(
      title: 'Search',
      headerExtra: SearchField(
        controller: _controller,
        hintText: 'Search posts, people, caregroups',
        onChanged: _onChanged,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OfflineBanner(),
          Expanded(child: _query.isEmpty ? _recent() : _results()),
        ],
      ),
    );
  }

  /// Before typing: recent searches, then suggestions (the campus's
  /// communities and the leaders of your own community), as designed.
  Widget _recent() {
    final recent = ref.watch(recentSearchesProvider);
    final suggestions = ref.watch(searchSuggestionsProvider).valueOrNull;
    if (recent.isEmpty && (suggestions == null || suggestions.isEmpty)) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Search FCU',
        body: 'Find caregroups and people by name or username.',
      );
    }
    return _ResultList(
      results: suggestions ?? SearchResults.empty,
      onCommunity: _openCommunity,
      onPerson: _openPerson,
      onPost: _openPost,
      header: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text('Recent', style: AppTextStyles.sectionHeading),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(_minTarget, _minTarget),
                ),
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).clear(),
                child: Semantics(
                  label: 'Clear recent searches',
                  excludeSemantics: true,
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
          for (final q in recent)
            Semantics(
              button: true,
              label: 'Search again for $q',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => _useRecent(q),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _minTarget),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.placeholder),
                      const SizedBox(width: _gap),
                      Expanded(child: Text(q, style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _results() {
    final query = _query;
    final results = ref.watch(searchResultsProvider(query));
    return results.when(
      loading: () => const Skeleton(showHeader: false),
      error: (_, _) => ErrorView(
        message: 'We could not search right now. Please try again.',
        onRetry: () => ref.invalidate(searchResultsProvider(query)),
      ),
      data: (r) => r.isEmpty
          ? EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results for “$query”',
              body: 'Try a different name or username.',
            )
          : _ResultList(
              results: r,
              onCommunity: _openCommunity,
              onPerson: _openPerson,
              onPost: _openPost,
            ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.results,
    required this.onCommunity,
    required this.onPerson,
    required this.onPost,
    this.header = const [],
  });

  static const _gap = 10.0;

  /// Shown above the results (the recent searches, before typing).
  final List<Widget> header;

  final SearchResults results;
  final ValueChanged<Community> onCommunity;
  final ValueChanged<MemberProfile> onPerson;
  final ValueChanged<Post> onPost;

  @override
  Widget build(BuildContext context) {
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: _gap),
      child: Text(text, style: AppTextStyles.sectionHeading),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...header,
        if (results.communities.isNotEmpty) ...[
          heading('Caregroups'),
          for (final c in results.communities)
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Semantics(
                button: true,
                label: 'Open caregroup ${c.name}',
                child: ListRowCard(
                  leading: InitialsAvatar(initials: c.initials, size: 48),
                  title: c.name,
                  subtitle: c.type == CommunityType.general
                      ? 'General caregroup'
                      : c.meetingDay,
                  onTap: () => onCommunity(c),
                ),
              ),
            ),
        ],
        if (results.posts.isNotEmpty) ...[
          heading('Posts'),
          for (final p in results.posts)
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Semantics(
                button: true,
                label: p.kind == PostKind.question
                    ? 'Open question: ${p.body}'
                    : 'Open post by ${p.displayName}',
                excludeSemantics: true,
                child: ListRowCard(
                  leading: InitialsAvatar(
                    initials: p.kind == PostKind.question
                        ? '?'
                        : p.displayInitials,
                    size: 48,
                  ),
                  title: p.body,
                  subtitle: [
                    if (p.kind == PostKind.question) 'Question' else 'Post',
                    p.displayName,
                    formatRelativeTime(p.createdAt),
                  ].join(' · '),
                  onTap: () => onPost(p),
                ),
              ),
            ),
        ],
        if (results.people.isNotEmpty) ...[
          heading('People'),
          for (final m in results.people)
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Semantics(
                button: true,
                label: 'Open profile of ${m.person.name}',
                child: ListRowCard(
                  leading: InitialsAvatar(
                    initials: m.person.initials,
                    size: 48,
                  ),
                  title: m.person.name,
                  subtitle: '@${m.username} · ${m.person.role.label}',
                  onTap: () => onPerson(m),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
