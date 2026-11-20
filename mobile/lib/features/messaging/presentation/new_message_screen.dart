import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../community/domain/member_profile.dart';
import '../../community/domain/membership.dart';
import '../../community/domain/person.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/member_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/messaging_repository.dart';
import 'widgets/message_person_button.dart';

/// Screen 54: New message (`/messages/new`). Mentors and members of the
/// user's community; tapping one opens or creates the conversation.
class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// The row being opened; blocks a second tap while it loads.
  String? _opening;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(Person person) async {
    if (_opening != null) return;
    setState(() => _opening = person.id);
    await openConversation(context, ref, person, replace: true);
    if (mounted) setState(() => _opening = null);
  }

  bool _matches(MemberProfile m) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        m.person.name.toLowerCase().contains(q) ||
        m.username.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(membershipProvider).valueOrNull;
    final communityId = membership?.status == MembershipStatus.approved
        ? membership?.communityId
        : null;

    return AmberHeaderScaffold(
      title: 'New message',
      headerExtra: SearchField(
        controller: _search,
        hintText: 'Search a member',
        onChanged: (value) => setState(() => _query = value),
      ),
      body: communityId == null
          ? EmptyState(
              icon: Icons.groups_outlined,
              title: 'Join a caregroup first',
              body:
                  'Mentors and members of your specific caregroup appear '
                  'here once your request is approved.',
              actionLabel: 'Find a caregroup',
              onAction: () => context.go('/communities'),
            )
          : _People(
              communityId: communityId,
              matches: _matches,
              opening: _opening,
              onOpen: _open,
            ),
    );
  }
}

class _People extends ConsumerWidget {
  const _People({
    required this.communityId,
    required this.matches,
    required this.opening,
    required this.onOpen,
  });

  final String communityId;
  final bool Function(MemberProfile) matches;
  final String? opening;
  final ValueChanged<Person> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(communityMemberProfilesProvider(communityId));
    final community = ref.watch(communityByIdProvider(communityId)).valueOrNull;
    final me = ref.watch(currentProfileProvider)?.id;
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    ref.watch(messagingRestrictedProvider);
    final threads = ref.read(threadRepositoryProvider);

    if (peopleAsync.isLoading && !peopleAsync.hasValue) {
      return const Skeleton(showHeader: false);
    }
    if (peopleAsync.hasError && !peopleAsync.hasValue) {
      return ErrorView(
        onRetry: () =>
            ref.invalidate(communityMemberProfilesProvider(communityId)),
      );
    }
    final people = [
      for (final m in peopleAsync.valueOrNull ?? const <MemberProfile>[])
        if (m.person.id != me && matches(m)) m,
    ];
    final mentors = people.where((m) => m.verified).toList();
    final members = people.where((m) => !m.verified).toList();

    Widget row(MemberProfile m, String subtitle) {
      final allowed = threads.canMessage(m.person);
      final enabled = allowed && online && opening == null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Semantics(
          button: true,
          enabled: enabled,
          label: allowed
              ? 'Message ${m.person.name}'
              : '${m.person.name}. ${MessagingRestricted.message}',
          excludeSemantics: true,
          child: ListRowCard(
            key: ValueKey(m.person.id),
            leading: Center(
              child: AvatarWithPresence(
                initials: m.person.initials,
                size: 44,
                online: m.person.online,
              ),
            ),
            title: m.person.name,
            subtitle: allowed
                ? subtitle
                : '$subtitle · ${MessagingRestricted.message}',
            opacity: allowed ? 1 : _disabledOpacity,
            trailing: opening == m.person.id
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: enabled ? () => onOpen(m.person) : null,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const OfflineBanner(),
        const SizedBox(height: 16),
        if (people.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            body: 'No one in your caregroup matches your search.',
          )
        else ...[
          if (mentors.isNotEmpty) ...[
            Text('Your mentors', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 10),
            for (final m in mentors) row(m, m.person.role.label),
            const SizedBox(height: 12),
          ],
          if (members.isNotEmpty) ...[
            Text(
              'Members of ${community?.name ?? 'your community'}',
              style: AppTextStyles.sectionHeading,
            ),
            const SizedBox(height: 10),
            for (final m in members) row(m, '@${m.username}'),
          ],
        ],
      ],
    );
  }
}

const double _disabledOpacity = 0.55;
