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

    if (communityAsync.isLoading || membersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final community = communityAsync.valueOrNull;
    final members = membersAsync.valueOrNull;
    if (community == null || members == null) {
      return Center(
        child: Text(
          'Could not load this community.',
          style: AppTextStyles.body,
        ),
      );
    }

    final onlineMembers = members.where((m) => m.online).toList();
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
                'Community info',
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
                      backgroundColor: AppColors.honey,
                    ),
                  if (community.room != null)
                    AppChip(
                      label: community.room!,
                      backgroundColor: AppColors.cream,
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
                  30.0 *
                      ((onlineMembers.length.clamp(0, 3) +
                                  (otherOnlineCount > 0 ? 1 : 0)) -
                              1)
                          .clamp(0, 3),
              child: Stack(
                children: [
                  for (var i = 0; i < onlineMembers.length && i < 3; i++)
                    Positioned(
                      left: i * 30.0,
                      child: AvatarWithPresence(
                        initials: onlineMembers[i].initials,
                        online: true,
                        backgroundColor:
                            onlineMembers[i].role == PersonRole.superMentor
                            ? AppColors.amber
                            : onlineMembers[i].role == PersonRole.mentor
                            ? AppColors.honey
                            : AppColors.cream,
                      ),
                    ),
                  if (otherOnlineCount > 0)
                    Positioned(
                      left: (onlineMembers.length.clamp(0, 3)) * 30.0,
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
              '${onlineMembers.length} online',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Members', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 10),
        for (var i = 0; i < members.length; i++) ...[
          ListRowCard(
            leading: Center(
              child: AvatarWithPresence(
                initials: members[i].initials,
                size: 40,
                online: members[i].online,
              ),
            ),
            title: members[i].name,
            subtitle: members[i].role.label,
            trailing: members[i].id == profile?.id
                ? null
                : MessagePersonButton(person: members[i]),
          ),
          if (i != members.length - 1) const SizedBox(height: 10),
        ],
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
          'Leave community',
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
