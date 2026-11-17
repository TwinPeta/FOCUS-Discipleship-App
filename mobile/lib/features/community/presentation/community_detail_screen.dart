import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/error_snack.dart';
import '../domain/membership.dart';
import '../domain/person.dart';
import '../../profile/presentation/profile_providers.dart';
import 'providers/community_providers.dart';
import 'providers/membership_provider.dart';
import 'widgets/community_cover.dart';
import 'widgets/leadership_row.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/utils/meeting_dates.dart';

/// Screen 4 of the brief: Community detail & request to join.
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  bool _isRequesting = false;

  Future<void> _requestToJoin() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      await ref
          .read(membershipProvider.notifier)
          .requestToJoin(widget.communityId);
    } on MembershipLimitReached {
      if (mounted) {
        showErrorSnack(
          context,
          'You already have a pending request or a specific community.',
        );
      }
      return;
    } catch (_) {
      if (mounted) showErrorSnack(context);
      return;
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
    if (!mounted) return;
    context.go('/communities');
  }

  /// Where this student stands with *this* community.
  _JoinStatus _statusFor(Membership m) {
    final here = m.communityId == widget.communityId;
    return switch (m.status) {
      MembershipStatus.approved when here => _JoinStatus.member,
      MembershipStatus.pending when here => _JoinStatus.pending,
      MembershipStatus.approved ||
      MembershipStatus.pending => _JoinStatus.elsewhere,
      MembershipStatus.rejected when here => _JoinStatus.declined,
      _ => _JoinStatus.none,
    };
  }

  Future<void> _cancelRequest() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      await ref.read(membershipProvider.notifier).cancelRequest();
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityAsync = ref.watch(communityByIdProvider(widget.communityId));
    final profile = ref.watch(currentProfileProvider);
    final membershipAsync = ref.watch(membershipProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: communityAsync.when(
        loading: () => const Skeleton(),
        error: (error, stackTrace) => ErrorScreen(
          onRetry: () =>
              ref.invalidate(communityByIdProvider(widget.communityId)),
        ),
        data: (community) {
          final membership = membershipAsync.valueOrNull ?? Membership.empty;
          final alreadyHasMembership =
              membership.status == MembershipStatus.pending ||
              membership.status == MembershipStatus.approved;
          final pendingHere =
              membership.status == MembershipStatus.pending &&
              membership.communityId == widget.communityId;

          return SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CommunityCover(
                          community: community,
                          institutionName:
                              profile?.institutionName ?? '[University]',
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                community.description,
                                style: AppTextStyles.body.copyWith(
                                  height: 1.55,
                                  color: AppColors.inkDeemphasized85,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'In-person meeting',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                label: community.meetingDay == null
                                    ? 'Day and time to be announced'
                                    : [
                                        community.meetingDay!,
                                        ?community.meetingTime,
                                      ].join(' · '),
                              ),
                              if (nextMeetingDate(
                                    community.meetingDay,
                                    community.meetingTime,
                                    DateTime.now(),
                                  )
                                  case final next?) ...[
                                const SizedBox(height: 10),
                                _InfoRow(
                                  icon: Icons.event_available_outlined,
                                  label: 'Next meeting: ${dayMonthLabel(next)}',
                                ),
                              ],
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.place_outlined,
                                label:
                                    community.room ?? 'Place to be announced',
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Leadership',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              LeadershipRow(
                                person:
                                    community.superMentor ??
                                    const Person(
                                      id: '',
                                      name: 'To be announced',
                                      role: PersonRole.superMentor,
                                    ),
                                roleLabel: 'Super-mentor',
                                color: AppColors.amber,
                              ),
                              if (community.mentors.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Mentors will be added soon.',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.inkDeemphasized80,
                                    ),
                                  ),
                                ),
                              for (final mentor in community.mentors)
                                LeadershipRow(
                                  person: mentor,
                                  roleLabel: 'Mentor',
                                  color: AppColors.honey,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _JoinStatusBar(
                  status: _statusFor(membership),
                  autoApprove: ref.watch(joinAutoApproveProvider),
                  isLoading: _isRequesting,
                  otherCommunityName:
                      alreadyHasMembership &&
                          membership.communityId != widget.communityId &&
                          membership.communityId != null
                      ? ref
                            .watch(
                              communityByIdProvider(membership.communityId!),
                            )
                            .valueOrNull
                            ?.name
                      : null,
                  declineNote: membership.message,
                  onJoin: _requestToJoin,
                  onCancel: pendingHere && !_isRequesting
                      ? _cancelRequest
                      : null,
                  onOpen: () =>
                      context.go('/community/${widget.communityId}/feed'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

enum _JoinStatus { none, pending, member, elsewhere, declined }

/// Bottom of screen 4: the student's join status for this community and
/// what they can do. Not joined: "Join community" (auto-approval on) or
/// "Request to join". Pending here: status + Cancel request. Member here:
/// "Go to community". In another community: why joining is off. Declined
/// here: the note and a way to ask again.
class _JoinStatusBar extends StatelessWidget {
  const _JoinStatusBar({
    required this.status,
    required this.autoApprove,
    required this.isLoading,
    required this.onJoin,
    required this.onOpen,
    this.onCancel,
    this.otherCommunityName,
    this.declineNote,
  });

  final _JoinStatus status;
  final bool autoApprove;
  final bool isLoading;
  final VoidCallback onJoin;
  final VoidCallback onOpen;
  final VoidCallback? onCancel;
  final String? otherCommunityName;
  final String? declineNote;

  @override
  Widget build(BuildContext context) {
    final (IconData? icon, String? title, String note) = switch (status) {
      _JoinStatus.none => (
        null,
        null,
        autoApprove
            ? 'You can join only one specific community. You join straight '
                  'away.'
            : 'You can join only one specific community. Your request goes '
                  'to the super-mentor for approval, and you will be '
                  'notified.',
      ),
      _JoinStatus.pending => (
        Icons.hourglass_top_rounded,
        'Request pending',
        'Waiting for the super-mentor. You will be notified when they '
            'decide.',
      ),
      _JoinStatus.member => (
        Icons.check_circle_rounded,
        "You're a member",
        'This is your specific community.',
      ),
      _JoinStatus.elsewhere => (
        Icons.info_outline_rounded,
        otherCommunityName == null
            ? 'You already have a community'
            : "You're already in $otherCommunityName",
        'A student can be in only one specific community.',
      ),
      _JoinStatus.declined => (
        Icons.do_not_disturb_on_outlined,
        'Not accepted this time',
        (declineNote?.trim().isNotEmpty ?? false)
            ? '"${declineNote!.trim()}"'
            : 'You can ask again or pick another community.',
      ),
    };

    final button = switch (status) {
      _JoinStatus.none || _JoinStatus.declined => AppPrimaryButton(
        label: status == _JoinStatus.declined
            ? (autoApprove ? 'Join again' : 'Request again')
            : (autoApprove ? 'Join community' : 'Request to join'),
        isLoading: isLoading,
        onPressed: onJoin,
      ),
      _JoinStatus.member => AppPrimaryButton(
        label: 'Go to community',
        onPressed: onOpen,
      ),
      _JoinStatus.pending || _JoinStatus.elsewhere => null,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cream, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: status == _JoinStatus.member
                      ? AppColors.honey
                      : AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: AppColors.ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                            note,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              color: AppColors.inkDeemphasized85,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (button != null) ...[
            if (title != null) const SizedBox(height: 12),
            button,
          ],
          if (title == null) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: AppTextStyles.fieldLabel.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.inkDeemphasized80,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onCancel != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size(44, 44),
              ),
              onPressed: onCancel,
              child: const Text(
                'Cancel request',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
