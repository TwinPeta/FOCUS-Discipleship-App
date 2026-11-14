import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/filter_chips.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../community/domain/membership.dart';
import '../../community/domain/person.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../data/messaging_repository.dart';
import '../domain/thread.dart';
import 'providers/messaging_providers.dart';

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

  Future<void> _openNewMessageSheet() async {
    final membership =
        ref.read(membershipProvider).valueOrNull ?? Membership.empty;
    // Only approved members may message a community's members (a pending
    // request is not membership).
    if (membership.status != MembershipStatus.approved ||
        membership.communityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join a specific community to message its members.'),
        ),
      );
      return;
    }
    final members = await ref.read(
      communityMembersProvider(membership.communityId!).future,
    );

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'New message',
                      style: AppTextStyles.sectionHeading,
                    ),
                  ),
                  // TODO(prompt3): /messages/new replaces this sheet.
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/messages/new');
                    },
                    child: const Text('Full screen'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final person = members[index];
                    return ListTile(
                      leading: AvatarWithPresence(
                        initials: person.initials,
                        size: 40,
                        online: person.online,
                      ),
                      title: Text(person.name),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        try {
                          final thread = await ref
                              .read(threadRepositoryProvider)
                              .openOrCreateThread(person, person.role.label);
                          ref.invalidate(threadsProvider);
                          if (!context.mounted) return;
                          unawaited(context.push('/messages/${thread.id}'));
                        } on MessagingRestricted {
                          if (context.mounted) {
                            showErrorSnack(
                              context,
                              MessagingRestricted.message,
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(threadsProvider);

    return AmberHeaderScaffold(
      title: 'Messages',
      headerAction: RoundIconButton(
        icon: Icons.edit_outlined,
        semanticLabel: 'New message',
        onPressed: _openNewMessageSheet,
      ),
      headerExtra: SizedBox(
        height: 50,
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search a member or message',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.placeholder,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.placeholder,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Could not load messages.', style: AppTextStyles.body),
        ),
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

          final header = <Widget>[
            FilterChips<_RoleFilter>(
              options: const [
                FilterChipOption(label: 'All', value: _RoleFilter.all),
                FilterChipOption(label: 'Mentors', value: _RoleFilter.mentors),
                FilterChipOption(label: 'Members', value: _RoleFilter.members),
              ],
              value: _roleFilter,
              onChanged: (value) => setState(() => _roleFilter = value),
            ),
            const SizedBox(height: 16),
          ];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: header.length + (filtered.isEmpty ? 1 : filtered.length),
            itemBuilder: (context, index) {
              if (index < header.length) return header[index];
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: threads.isEmpty
                      ? 'No conversations yet'
                      : 'No matches',
                  body: threads.isEmpty
                      ? 'Message a mentor or member to start one.'
                      : 'No messages match your search.',
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
                    color: AppColors.amber,
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
