import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/bottom_sheet_scaffold.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../messaging/presentation/widgets/message_person_button.dart';
import '../../moderation/presentation/moderation_providers.dart';
import '../domain/community.dart';
import '../domain/person.dart';
import 'providers/community_providers.dart';
import 'providers/join_request_providers.dart';
import 'providers/manage_providers.dart';

const _tileSize = 48.0;
const _cardGap = 12.0;

/// Screen 30: Manage {community} (`/community/:id/manage`). Super-mentors
/// only: the route guard and every repository behind the counters check.
class ManageCommunityScreen extends ConsumerWidget {
  const ManageCommunityScreen({super.key, required this.communityId});

  final String communityId;

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(communityByIdProvider(communityId))
      ..invalidate(pendingJoinRequestsProvider(communityId))
      ..invalidate(openModerationCasesProvider(communityId))
      ..invalidate(membersToFollowUpProvider(communityId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityByIdProvider(communityId));
    final requests = ref.watch(pendingJoinRequestsProvider(communityId));
    final cases = ref.watch(openModerationCasesProvider(communityId));
    final followUp = ref.watch(membersToFollowUpProvider(communityId));
    final all = [community, requests, cases, followUp];

    final Widget body;
    if (all.any((a) => a.hasError && !a.hasValue)) {
      body = ErrorView(onRetry: () => _retry(ref));
    } else if (all.any((a) => !a.hasValue)) {
      body = const Skeleton(showHeader: false, cardCount: 3);
    } else {
      body = _ManageBody(
        community: community.requireValue,
        requestCount: requests.requireValue.length,
        caseCount: cases.requireValue.length,
        followUp: followUp.requireValue,
      );
    }

    return AmberHeaderScaffold(
      title: community.hasValue
          ? 'Manage ${community.requireValue.name}'
          : 'Manage community',
      subtitle: 'Only super-mentors see this.',
      body: body,
    );
  }
}

class _ManageBody extends StatelessWidget {
  const _ManageBody({
    required this.community,
    required this.requestCount,
    required this.caseCount,
    required this.followUp,
  });

  final Community community;
  final int requestCount;
  final int caseCount;
  final List<Person> followUp;

  @override
  Widget build(BuildContext context) {
    final base = '/community/${community.id}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const OfflineBanner(),
        _ManageCard(
          icon: Icons.how_to_reg_rounded,
          title: 'Join requests',
          subtitle: 'Approve or decline students',
          count: requestCount,
          onTap: () => unawaited(context.push('$base/manage/requests')),
        ),
        const SizedBox(height: _cardGap),
        _ManageCard(
          icon: Icons.flag_outlined,
          title: 'Reports to review',
          subtitle: 'Level 1 moderation',
          count: caseCount,
          onTap: () => unawaited(context.push('$base/manage/reports')),
        ),
        const SizedBox(height: _cardGap),
        _ManageCard(
          icon: Icons.person_search_outlined,
          title: 'Members to follow up',
          subtitle: 'No activity for 14+ days',
          count: followUp.length,
          onTap: () => _showFollowUp(context),
        ),
        const SizedBox(height: _cardGap),
        _ManageCard(
          icon: Icons.event_outlined,
          title: 'Meeting details',
          subtitle: meetingSummary(community),
          onTap: () => unawaited(context.push('$base/meetings')),
        ),
        const SizedBox(height: 24),
        Text(
          'Cover photos and community creation are managed by the admin '
          'team.',
          style: AppTextStyles.body.copyWith(color: AppColors.placeholder),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showFollowUp(BuildContext context) {
    unawaited(
      showAppBottomSheet<void>(
        context,
        builder: (_) => BottomSheetScaffold(
          title: 'Members to follow up',
          children: [
            Text(
              followUp.isEmpty
                  ? 'Everyone has been active in the last 14 days.'
                  : 'No activity for 14+ days. A short message can help.',
              style: AppTextStyles.body,
            ),
            for (final p in followUp) ...[
              const SizedBox(height: 10),
              ListRowCard(
                leading: InitialsAvatar(initials: p.initials, size: _tileSize),
                title: p.name,
                subtitle: p.role.label,
                trailing: MessagePersonButton(person: p),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Tuesday · 5:00 PM · Room 204, Student Centre".
String meetingSummary(Community c) {
  final day = c.meetingDay?.replaceFirst(RegExp(r'^Every\s+'), '');
  final parts = [day, c.meetingTime, c.room].whereType<String>();
  return parts.isEmpty ? 'Not set yet' : parts.join(' · ');
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count == null ? null : '$title, $count',
      child: ListRowCard(
        leading: Container(
          width: _tileSize,
          height: _tileSize,
          decoration: BoxDecoration(
            color: AppColors.honey,
            borderRadius: BorderRadius.circular(AppRadii.tile),
          ),
          child: Icon(icon, color: AppColors.ink),
        ),
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count != null) AppChip(label: '$count'),
            Icon(Icons.chevron_right_rounded, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
