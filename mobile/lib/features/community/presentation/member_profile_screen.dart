import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../messaging/data/messaging_repository.dart';
import '../../messaging/domain/report.dart';
import '../../messaging/presentation/content_report_screens.dart';
import '../../messaging/presentation/providers/moderation_providers.dart';
import '../../messaging/presentation/widgets/block_person.dart';
import '../../messaging/presentation/widgets/message_person_button.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/member_profile.dart';
import 'providers/member_providers.dart';

/// Screen 43: Member profile (`/members/:id`).
class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider(memberId));
    final profile = profileAsync.valueOrNull;
    final me = ref.watch(currentProfileProvider);
    final isMe = me?.id == memberId;
    final blocked =
        ref.watch(blockedUserIdsProvider).valueOrNull?.contains(memberId) ??
        false;
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    ref.watch(messagingRestrictedProvider);
    final canMessage =
        profile != null &&
        ref.read(threadRepositoryProvider).canMessage(profile.person);
    final showActions = profile != null && !isMe && !blocked;

    void message() => openConversation(context, ref, profile!.person);

    return AmberHeaderScaffold(
      title: profile?.person.name ?? 'Member',
      subtitle: profile == null ? null : '@${profile.username}',
      headerAction: showActions
          ? RoundIconButton(
              icon: Icons.mail_outline_rounded,
              semanticLabel: canMessage
                  ? 'Message ${profile.person.name}'
                  : MessagingRestricted.message,
              onPressed: canMessage && online ? message : null,
            )
          : null,
      body: switch (profileAsync) {
        AsyncValue(isLoading: true, hasValue: false) => const Skeleton(
          showHeader: false,
          cardCount: 2,
        ),
        AsyncValue(hasError: true, hasValue: false) => ErrorView(
          onRetry: () => ref.invalidate(memberProfileProvider(memberId)),
        ),
        _ when profile == null => const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Member not available',
          body: 'This profile does not exist or is no longer available.',
        ),
        _ => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const OfflineBanner(),
            const SizedBox(height: 16),
            if (blocked)
              _BlockedCard(profile: profile, online: online)
            else ...[
              _ProfileCard(
                profile: profile,
                viewerInstitution: me?.institutionName,
              ),
              if (showActions) ...[
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Message',
                  onPressed: canMessage && online ? message : null,
                ),
                if (!canMessage) ...[
                  const SizedBox(height: 8),
                  Text(
                    MessagingRestricted.message,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: 'Report',
                  icon: Icons.flag_outlined,
                  onPressed: () => context.push(
                    contentReportLocation(
                      type: ReportTargetType.user,
                      id: memberId,
                      authorId: memberId,
                      authorName: profile.person.name,
                      back: '/members/$memberId',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: 'Block',
                  icon: Icons.block_rounded,
                  onPressed: online
                      ? () async {
                          final router = GoRouter.of(context);
                          if (await confirmAndBlock(
                            context,
                            ref,
                            profile.person,
                          )) {
                            router.canPop()
                                ? router.pop()
                                : router.go('/communities');
                          }
                        }
                      : null,
                ),
              ],
            ],
          ],
        ),
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.viewerInstitution});

  final MemberProfile profile;
  final String? viewerInstitution;

  @override
  Widget build(BuildContext context) {
    final person = profile.person;
    final institution = profile.institution ?? viewerInstitution;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWithPresence(
                initials: person.initials,
                size: _avatarSize,
                online: person.online,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RoleBadge(label: person.role.label),
                    if (profile.verified) const _VerifiedPill(),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('About', style: AppTextStyles.cardTitle),
            const SizedBox(height: 6),
            Text(profile.bio!, style: AppTextStyles.body.copyWith(height: 1.5)),
          ],
          if (institution != null || profile.communityName != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (institution != null)
                  AppChip(
                    label: institution,
                    icon: Icons.school_outlined,
                    backgroundColor: AppColors.cream,
                  ),
                if (profile.communityName != null)
                  AppChip(
                    label: profile.communityName!,
                    icon: Icons.groups_outlined,
                    backgroundColor: AppColors.cream,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text('Badges', style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          if (profile.badges.isEmpty)
            Text(
              'No badges yet.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.inkDeemphasized80,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final badge in profile.badges)
                  AppChip(
                    label: badge.name,
                    icon: Icons.workspace_premium_outlined,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

const double _avatarSize = 72;

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, size: 16, color: AppColors.ink),
          const SizedBox(width: 4),
          Text('Verified', style: AppTextStyles.chip),
        ],
      ),
    );
  }
}

/// A blocked member's profile: only their name and a way back.
class _BlockedCard extends ConsumerStatefulWidget {
  const _BlockedCard({required this.profile, required this.online});

  final MemberProfile profile;
  final bool online;

  @override
  ConsumerState<_BlockedCard> createState() => _BlockedCardState();
}

class _BlockedCardState extends ConsumerState<_BlockedCard> {
  bool _busy = false;

  Future<void> _unblock() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(moderationActionsProvider)
          .unblock(widget.profile.person.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.profile.person.name} is unblocked.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not unblock. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EmptyState(
          icon: Icons.block_rounded,
          title: 'You blocked this person',
          body: 'They cannot message you and you do not see their content.',
        ),
        AppSecondaryButton(
          label: 'Unblock',
          isLoading: _busy,
          onPressed: _busy || !widget.online ? null : _unblock,
        ),
      ],
    );
  }
}
