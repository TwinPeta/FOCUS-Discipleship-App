import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/domain/user_role.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../feed/presentation/providers/feed_providers.dart';
import '../../messaging/domain/report.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../../prayer/presentation/providers/prayer_providers.dart';
import '../../testimony/presentation/providers/testimony_providers.dart';
import '../data/moderation_queue_repository.dart';
import '../domain/moderation_case.dart';
import 'moderation_providers.dart';

const _actionHeight = 44.0;
const _actionGap = 10.0;

/// Screen 32: Reports to review (`/community/:id/manage/reports`).
/// Super-mentors only: the route guard and the repository both check.
class ReportsToReviewScreen extends ConsumerWidget {
  const ReportsToReviewScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityByIdProvider(communityId)).valueOrNull;
    final cases = ref.watch(openModerationCasesProvider(communityId));

    return AmberHeaderScaffold(
      title: 'Reports to review',
      subtitle: community?.name,
      body: cases.when(
        loading: () => const Skeleton(showHeader: false, cardCount: 2),
        error: (_, _) => ErrorView(
          onRetry: () =>
              ref.invalidate(openModerationCasesProvider(communityId)),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const OfflineBanner(),
            Text(
              'You can hide content and warn members. Admins handle '
              'suspensions.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.verified_user_rounded,
                title: 'Nothing to review',
                body: 'Reports from members of your community appear here.',
              )
            else
              for (final c in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CaseCard(
                    key: ValueKey(c.id),
                    item: c,
                    communityId: communityId,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends ConsumerStatefulWidget {
  const _CaseCard({super.key, required this.item, required this.communityId});

  final ModerationCase item;
  final String communityId;

  @override
  ConsumerState<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends ConsumerState<_CaseCard> {
  ModerationOutcome? _busy;

  ModerationCase get _c => widget.item;

  Future<void> _act(ModerationOutcome outcome) async {
    if (_busy != null) return;
    if (outcome == ModerationOutcome.warned) {
      final ok = await showConfirmDialog(
        context,
        title: 'Warn ${_c.authorName}?',
        message:
            'The ${_c.content.label.toLowerCase()} is hidden and '
            '${_c.authorName} sees a warning with the reason.',
        confirmLabel: 'Warn author',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy = outcome);
    final repo = ref.read(moderationQueueRepositoryProvider);
    final role = ref.read(currentRoleProvider);
    try {
      await _call(repo, outcome, role);
      if (!mounted) return;
      ref.invalidate(openModerationCasesProvider(widget.communityId));
      if (outcome == ModerationOutcome.hidden ||
          outcome == ModerationOutcome.warned) {
        // Hidden content disappears from every feed right away.
        ref.invalidate(feedPostsProvider);
        ref.invalidate(prayerRequestsProvider);
        ref.invalidate(testimoniesProvider);
      }
      ref.invalidate(notificationsProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_doneText(outcome))));
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<ModerationCase> _call(
    ModerationQueueRepository repo,
    ModerationOutcome outcome,
    UserRole? role,
  ) => switch (outcome) {
    ModerationOutcome.hidden => repo.hide(_c.id, actorRole: role),
    ModerationOutcome.warned => repo.warnAuthor(_c.id, actorRole: role),
    ModerationOutcome.kept => repo.keep(_c.id, actorRole: role),
    ModerationOutcome.escalated => repo.escalate(_c.id, actorRole: role),
  };

  String _doneText(ModerationOutcome outcome) => switch (outcome) {
    ModerationOutcome.hidden => '${_c.content.label} hidden',
    ModerationOutcome.warned => '${_c.authorName} was warned',
    ModerationOutcome.kept => '${_c.content.label} kept',
    ModerationOutcome.escalated => 'Sent to the admin team',
  };

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final enabled = _busy == null && online;

    Widget primary(String label, ModerationOutcome o) => AppPrimaryButton(
      label: label,
      height: _actionHeight,
      isLoading: _busy == o,
      onPressed: enabled ? () => _act(o) : null,
    );
    Widget secondary(String label, ModerationOutcome o) => AppSecondaryButton(
      label: label,
      height: _actionHeight,
      isLoading: _busy == o,
      onPressed: enabled ? () => _act(o) : null,
    );

    final reports = _c.reportCount == 1 ? 'report' : 'reports';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${_c.content.label} by ${_c.authorName}',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              const SizedBox(width: 8),
              AppChip(label: 'Level ${_c.level}'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatDayLabel(_c.reportedAt)} · Reported by '
            '${_c.firstReporterName}',
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.page,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              _c.preview,
              style: AppTextStyles.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_c.reportCount} $reports · ${_c.reason.label}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: primary('Hide', ModerationOutcome.hidden)),
              const SizedBox(width: _actionGap),
              Expanded(
                child: _c.canWarn
                    ? primary('Warn author', ModerationOutcome.warned)
                    : const AppPrimaryButton(
                        label: 'Author unknown',
                        height: _actionHeight,
                      ),
              ),
            ],
          ),
          const SizedBox(height: _actionGap),
          Row(
            children: [
              Expanded(child: secondary('Keep', ModerationOutcome.kept)),
              const SizedBox(width: _actionGap),
              Expanded(
                child: secondary(
                  'Escalate to admin',
                  ModerationOutcome.escalated,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
