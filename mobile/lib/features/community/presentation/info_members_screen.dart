import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../messaging/presentation/providers/messaging_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/person.dart';
import 'providers/community_providers.dart';

String _roleLabel(PersonRole role) => switch (role) {
  PersonRole.superMentor => 'Super-mentor',
  PersonRole.mentor => 'Mentor',
  PersonRole.member => 'Member',
};

/// Screen 6: Info & members tab inside [CommunityShell].
class InfoMembersScreen extends ConsumerWidget {
  const InfoMembersScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(communityByIdProvider(communityId));
    final membersAsync = ref.watch(communityMembersProvider(communityId));
    final profile = ref.watch(currentProfileProvider);

    if (communityAsync.isLoading || membersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final community = communityAsync.valueOrNull;
    final members = membersAsync.valueOrNull;
    if (community == null || members == null) {
      return Center(
        child: Text('Could not load this community.', style: AppTextStyles.body),
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
                  if (community.meetingDay != null && community.meetingTime != null)
                    AppChip(
                      label: '${community.meetingDay} · ${community.meetingTime}',
                      backgroundColor: AppColors.honey,
                    ),
                  if (community.room != null)
                    AppChip(label: community.room!, backgroundColor: AppColors.cream),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Online now', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              height: 44,
              child: Stack(
                children: [
                  for (var i = 0; i < onlineMembers.length && i < 3; i++)
                    Positioned(
                      left: i * 30.0,
                      child: AvatarWithPresence(
                        initials: onlineMembers[i].initials,
                        online: true,
                        backgroundColor: onlineMembers[i].role == PersonRole.superMentor
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
                          border: Border.all(color: AppColors.inputBorder, width: 1.5),
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
            Text('${onlineMembers.length} online', style: AppTextStyles.bodyMedium),
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
            subtitle: _roleLabel(members[i].role),
            trailing: members[i].id == profile?.id
                ? null
                : _MessageButton(person: members[i]),
          ),
          if (i != members.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MessageButton extends ConsumerWidget {
  const _MessageButton({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Message ${person.name}',
      child: InkWell(
        onTap: () async {
          final thread = await ref
              .read(threadRepositoryProvider)
              .openOrCreateThread(person, _roleLabel(person.role));
          ref.invalidate(threadsProvider);
          if (!context.mounted) return;
          context.push('/messages/${thread.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.mail_outline_rounded, color: AppColors.ink, size: 20),
        ),
      ),
    );
  }
}
