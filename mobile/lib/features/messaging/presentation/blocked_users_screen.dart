import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/member_profile.dart';
import '../../community/presentation/providers/member_providers.dart';
import 'providers/moderation_providers.dart';

/// Screen 55: Blocked users (`/settings/blocked`).
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends ConsumerState<BlockedUsersScreen> {
  /// Ids being unblocked right now (no double tap).
  final Set<String> _busy = {};

  Future<void> _unblock(MemberProfile m) async {
    if (!_busy.add(m.person.id)) return;
    setState(() {});
    try {
      await ref.read(moderationActionsProvider).unblock(m.person.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.person.name} is unblocked.')),
        );
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not unblock. Try again.');
    } finally {
      _busy.remove(m.person.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedAsync = ref.watch(blockedMembersProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final blocked = blockedAsync.valueOrNull ?? const <MemberProfile>[];

    return AmberHeaderScaffold(
      title: 'Blocked users',
      subtitle: 'Blocked people cannot message you.',
      body: switch (blockedAsync) {
        AsyncValue(isLoading: true, hasValue: false) => const Skeleton(
          showHeader: false,
        ),
        AsyncValue(hasError: true, hasValue: false) => ErrorView(
          onRetry: () => ref.invalidate(blockedMembersProvider),
        ),
        // Scrolls, so large text never overflows.
        _ when blocked.isEmpty => ListView(
          children: const [
            EmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No one is blocked',
              body: 'People you block from their profile appear here.',
            ),
          ],
        ),
        _ => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const OfflineBanner(),
            const SizedBox(height: 16),
            for (final m in blocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListRowCard(
                  key: ValueKey(m.person.id),
                  leading: Center(
                    child: AvatarWithPresence(
                      initials: m.person.initials,
                      size: 44,
                    ),
                  ),
                  title: m.person.name,
                  subtitle: '@${m.username}',
                  onTap: () => context.push('/members/${m.person.id}'),
                  trailing: PillButton(
                    label: _busy.contains(m.person.id)
                        ? 'Unblocking…'
                        : 'Unblock',
                    semanticLabel: 'Unblock ${m.person.name}',
                    onTap: online && !_busy.contains(m.person.id)
                        ? () => _unblock(m)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      },
    );
  }
}
