import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/person.dart';
import '../domain/user_role.dart';
import 'providers/membership_provider.dart';
import '../../messaging/presentation/widgets/message_person_button.dart';
import 'widgets/leave_community_sheet.dart';
import 'providers/community_providers.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/realtime/realtime_bindings.dart';
import '../../../core/widgets/search_field.dart';

/// Screen 6: Info & members tab inside [CommunityShell].
class InfoMembersScreen extends ConsumerWidget {
  const InfoMembersScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(communityByIdProvider(communityId));
    final membersAsync = ref.watch(communityMembersProvider(communityId));
    final profile = ref.watch(currentProfileProvider);
    final isSuperMentor =
        ref.watch(currentRoleProvider) == UserRole.superMentor;

    final community = communityAsync.valueOrNull;
    final members = membersAsync.valueOrNull;
    if (communityAsync.hasError || membersAsync.hasError) {
      if (community == null || members == null) {
        return ErrorView(
          onRetry: () => ref
            ..invalidate(communityByIdProvider(communityId))
            ..invalidate(communityMembersProvider(communityId)),
        );
      }
    }
    if (community == null || members == null) {
      return const Skeleton(showHeader: false, cardCount: 2);
    }

    final onlineMembers = members.where((m) => m.online).toList();
    // The live count from the server when known (it updates as people come
    // and go), otherwise the members marked online.
    final onlineCount =
        ref.watch(liveOnlineCountsProvider)[communityId] ??
        onlineMembers.length;
    final otherOnlineCount = (onlineMembers.length - 3).clamp(0, 999);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
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
                'Caregroup info',
                style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                community.description,
                style: AppTextStyles.body.copyWith(height: 1.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (community.meetingDay != null &&
                      community.meetingTime != null)
                    AppChip(
                      label:
                          '${community.meetingDay} · ${community.meetingTime}',
                      backgroundColor: AppColors.primarySoft,
                    ),
                  if (community.room != null)
                    AppChip(
                      label: community.room!,
                      backgroundColor: AppColors.primarySoft,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppSecondaryButton(
          label: 'View meetings',
          icon: Icons.event_outlined,
          height: 46,
          onPressed: () => context.push('/community/$communityId/meetings'),
        ),
        const SizedBox(height: 20),
        Text('Online now', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              height: 44,
              width:
                  44 +
                  36.0 *
                      ((onlineMembers.length.clamp(0, 3) +
                                  (otherOnlineCount > 0 ? 1 : 0)) -
                              1)
                          .clamp(0, 3),
              child: Stack(
                children: [
                  for (var i = 0; i < onlineMembers.length && i < 3; i++)
                    Positioned(
                      left: i * 36.0,
                      child: AvatarWithPresence(
                        initials: onlineMembers[i].initials,
                        online: true,
                        backgroundColor:
                            onlineMembers[i].role == PersonRole.superMentor
                            ? AppColors.amber
                            : onlineMembers[i].role == PersonRole.mentor
                            ? AppColors.honey
                            : AppColors.primarySoft,
                      ),
                    ),
                  if (otherOnlineCount > 0)
                    Positioned(
                      left: (onlineMembers.length.clamp(0, 3)) * 36.0,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.inputBorder,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$otherOnlineCount',
                          style: AppTextStyles.chip,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              onlineCount == 0 ? 'No one online' : '$onlineCount online',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MembersSection(members: members, meId: profile?.id),
        if (!isSuperMentor) ...[
          const SizedBox(height: 24),
          _LeaveButton(
            onPressed: () => showLeaveCommunitySheet(context, community),
          ),
        ],
      ],
    );
  }
}

/// Outlined, destructive-worded; the confirmation sheet arrives in prompt 2.
class _LeaveButton extends StatelessWidget {
  const _LeaveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 46,
        minWidth: double.infinity,
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Leave caregroup',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
    );
  }
}

const _searchFrom = 8;

/// "Members · n": leaders first, then who is online, then by name. Tap a
/// member for their profile; the chat button starts a direct message.
/// A search box appears for longer lists.
class _MembersSection extends StatefulWidget {
  const _MembersSection({required this.members, required this.meId});

  final List<Person> members;
  final String? meId;

  @override
  State<_MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<_MembersSection> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static int _rank(Person p) => switch (p.role) {
    PersonRole.superMentor => 0,
    PersonRole.mentor => 1,
    _ => 2,
  };

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list =
        widget.members
            .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
            .toList()
          ..sort((a, b) {
            final byRole = _rank(a).compareTo(_rank(b));
            if (byRole != 0) return byRole;
            if (a.online != b.online) return a.online ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Members · ${widget.members.length}',
          style: AppTextStyles.sectionHeading,
        ),
        if (widget.members.length >= _searchFrom) ...[
          const SizedBox(height: 10),
          SearchField(
            controller: _search,
            hintText: 'Search members',
            onChanged: (v) => setState(() => _query = v),
          ),
        ],
        const SizedBox(height: 10),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No members match your search.',
              style: AppTextStyles.body,
            ),
          ),
        for (var i = 0; i < list.length; i++) ...[
          ListRowCard(
            onTap: () => context.push('/members/${list[i].id}'),
            leading: Center(
              child: AvatarWithPresence(
                initials: list[i].initials,
                size: 40,
                online: list[i].online,
              ),
            ),
            title: list[i].id == widget.meId
                ? '${list[i].name} (you)'
                : list[i].name,
            subtitle: list[i].online
                ? '${list[i].role.label} · Online'
                : list[i].role.label,
            trailing: list[i].id == widget.meId
                ? null
                : MessagePersonButton(person: list[i]),
          ),
          if (i != list.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
