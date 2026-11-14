import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../domain/join_request.dart';
import 'providers/community_providers.dart';
import 'providers/join_request_providers.dart';
import 'providers/membership_provider.dart';

const _actionHeight = 44.0;
const _avatarSize = 44.0;

/// Screen 31: Join requests (`/community/:id/manage/requests`). Super-mentors
/// only: the route guard and the repository both check the role.
class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityByIdProvider(communityId)).valueOrNull;
    final requests = ref.watch(pendingJoinRequestsProvider(communityId));

    return AmberHeaderScaffold(
      title: 'Join requests',
      subtitle: community?.name,
      body: requests.when(
        loading: () => const Skeleton(showHeader: false, cardCount: 3),
        error: (_, _) => ErrorView(
          onRetry: () =>
              ref.invalidate(pendingJoinRequestsProvider(communityId)),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const OfflineBanner(),
            Text(
              'A student can be in only one specific community.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.how_to_reg_rounded,
                title: 'No join requests',
                body: 'New requests from students will appear here.',
              )
            else
              for (final r in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _JoinRequestCard(
                    key: ValueKey(r.id),
                    request: r,
                    communityId: communityId,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _JoinRequestCard extends ConsumerStatefulWidget {
  const _JoinRequestCard({
    super.key,
    required this.request,
    required this.communityId,
  });

  final JoinRequest request;
  final String communityId;

  @override
  ConsumerState<_JoinRequestCard> createState() => _JoinRequestCardState();
}

enum _Busy { none, approving, declining }

class _JoinRequestCardState extends ConsumerState<_JoinRequestCard> {
  var _busy = _Busy.none;

  JoinRequest get _r => widget.request;

  Future<void> _run(
    _Busy kind,
    Future<JoinRequest> Function() call,
    String done,
  ) async {
    if (_busy != _Busy.none) return;
    setState(() => _busy = kind);
    try {
      await call();
      if (!mounted) return;
      ref.invalidate(pendingJoinRequestsProvider(widget.communityId));
      ref.invalidate(notificationsProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    } on StudentAlreadyInCommunity catch (e) {
      if (mounted) {
        showErrorSnack(
          context,
          '${_r.studentName} is already in ${e.communityName}.',
        );
      }
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _approve() => _run(
    _Busy.approving,
    () => ref
        .read(joinRequestRepositoryProvider)
        .approve(_r.id, actorRole: ref.read(currentRoleProvider)),
    '${_r.studentName} approved',
  );

  Future<void> _decline() async {
    if (_busy != _Busy.none) return;
    final message = await showTextInputDialog(
      context,
      title: 'Decline ${_r.studentName}?',
      hint: 'Add a message for the student (optional)',
      confirmLabel: 'Decline',
    );
    if (message == null || !mounted) return; // cancelled
    await _run(
      _Busy.declining,
      () => ref
          .read(joinRequestRepositoryProvider)
          .decline(
            _r.id,
            actorRole: ref.read(currentRoleProvider),
            message: message,
          ),
      '${_r.studentName} declined',
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final idle = _busy == _Busy.none && online;
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
              InitialsAvatar(
                initials: initialsOf(_r.studentName),
                size: _avatarSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _r.studentName,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${_r.username} · ${_r.institution}',
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _requestedLabel(_r.requestedAt),
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_r.existingCommunityName != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Already in ${_r.existingCommunityName}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: 'Approve',
                  height: _actionHeight,
                  isLoading: _busy == _Busy.approving,
                  onPressed: idle && _r.canApprove ? _approve : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppSecondaryButton(
                  label: 'Decline',
                  height: _actionHeight,
                  isLoading: _busy == _Busy.declining,
                  onPressed: idle ? _decline : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Requested today", "Requested yesterday", "Requested on Monday"...
String _requestedLabel(DateTime at) {
  final day = formatDayLabel(at);
  return day == 'Today' || day == 'Yesterday'
      ? 'Requested ${day.toLowerCase()}'
      : 'Requested on $day';
}
