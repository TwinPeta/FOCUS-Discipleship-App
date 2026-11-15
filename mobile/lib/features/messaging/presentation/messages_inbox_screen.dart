import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/filter_chips.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/person.dart';
import '../domain/thread.dart';
import 'providers/messaging_providers.dart';
import '../../../core/theme/app_gradients.dart';

enum _RoleFilter { all, mentors, members }

/// Screen 9: Messages inbox.
class MessagesInboxScreen extends ConsumerStatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  ConsumerState<MessagesInboxScreen> createState() =>
      _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends ConsumerState<MessagesInboxScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _RoleFilter _roleFilter = _RoleFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(threadsProvider);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.messages),
      body: AmberHeaderScaffold(
        title: 'Messages',
        headerAction: RoundIconButton(
          icon: Icons.edit_outlined,
          semanticLabel: 'New message',
          onPressed: () => context.push('/messages/new'),
        ),
        headerExtra: SearchField(
          controller: _searchController,
          hintText: 'Search a member or message',
          onChanged: (value) => setState(() => _query = value),
        ),
        body: threadsAsync.when(
          loading: () => const Skeleton(showHeader: false),
          error: (error, stackTrace) =>
              ErrorView(onRetry: () => ref.invalidate(threadsProvider)),
          data: (threads) {
            var filtered = threads;
            if (_roleFilter == _RoleFilter.mentors) {
              filtered = filtered
                  .where((t) => t.participant.role != PersonRole.member)
                  .toList();
            } else if (_roleFilter == _RoleFilter.members) {
              filtered = filtered
                  .where((t) => t.participant.role == PersonRole.member)
                  .toList();
            }
            if (_query.trim().isNotEmpty) {
              final q = _query.trim().toLowerCase();
              filtered = filtered
                  .where(
                    (t) =>
                        t.participant.name.toLowerCase().contains(q) ||
                        t.lastMessage.toLowerCase().contains(q),
                  )
                  .toList();
            }

            if (threads.isEmpty) {
              return EmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No messages yet',
                body: 'Say hello to a mentor or a member of your community.',
                actionLabel: 'Find a member',
                onAction: () => context.push('/messages/new'),
              );
            }

            final header = <Widget>[
              const OfflineBanner(),
              const SizedBox(height: 4),
              FilterChips<_RoleFilter>(
                options: const [
                  FilterChipOption(label: 'All', value: _RoleFilter.all),
                  FilterChipOption(
                    label: 'Mentors',
                    value: _RoleFilter.mentors,
                  ),
                  FilterChipOption(
                    label: 'Members',
                    value: _RoleFilter.members,
                  ),
                ],
                value: _roleFilter,
                onChanged: (value) => setState(() => _roleFilter = value),
              ),
              const SizedBox(height: 16),
            ];
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount:
                  header.length + (filtered.isEmpty ? 1 : filtered.length),
              itemBuilder: (context, index) {
                if (index < header.length) return header[index];
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    body: 'No messages match your search.',
                  );
                }
                final thread = filtered[index - header.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ThreadRow(key: ValueKey(thread.id), thread: thread),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({super.key, required this.thread});

  final Thread thread;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${thread.participant.name}, ${thread.lastMessage}',
      child: InkWell(
        onTap: () => context.push('/messages/${thread.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              AvatarWithPresence(
                initials: thread.participant.initials,
                size: 52,
                online: thread.participant.online,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.participant.name,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatRelativeTime(thread.lastAt),
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.inkDeemphasized80,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    RoleBadge(label: thread.roleLabel),
                    const SizedBox(height: 4),
                    Text(
                      thread.lastMessage,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        color: AppColors.ink.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (thread.unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.brand,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${thread.unread}',
                    style: AppTextStyles.chip.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
