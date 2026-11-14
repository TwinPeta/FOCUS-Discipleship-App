import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../domain/app_notification.dart';
import 'notification_providers.dart';

const _tileSize = 44.0;
const _dotSize = 10.0;

IconData _iconFor(NotificationType type) => switch (type) {
  NotificationType.requestApproved => Icons.check_circle_outline_rounded,
  NotificationType.requestDeclined => Icons.info_outline_rounded,
  NotificationType.commentReply => Icons.chat_bubble_outline_rounded,
  NotificationType.prayedForYou ||
  NotificationType.prayerResponse => Icons.volunteer_activism_outlined,
  NotificationType.announcement => Icons.campaign_outlined,
  NotificationType.meetingReminder => Icons.event_outlined,
  NotificationType.inactivity => Icons.waving_hand_outlined,
  NotificationType.moderatorWarning => Icons.shield_outlined,
};

/// Screen 44: Notifications (`/notifications`). Back goes to the hub.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    try {
      if (!n.isRead) {
        await ref.read(notificationRepositoryProvider).markRead(n.id);
        ref.invalidate(notificationsProvider);
      }
      if (context.mounted) unawaited(context.push(n.targetRoute));
    } catch (_) {
      if (context.mounted) showErrorSnack(context);
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
    } catch (_) {
      if (context.mounted) showErrorSnack(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    return AmberHeaderScaffold(
      title: 'Notifications',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/communities'),
      headerAction: RoundIconButton(
        icon: Icons.settings_outlined,
        semanticLabel: 'Notification settings',
        onPressed: () => context.push('/notifications/settings'),
      ),
      body: items.when(
        loading: () => const Skeleton(showHeader: false, cardCount: 3),
        error: (_, _) =>
            ErrorView(onRetry: () => ref.invalidate(notificationsProvider)),
        data: (all) {
          final fresh = all.where((n) => !n.isRead).toList();
          final earlier = all.where((n) => n.isRead).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const OfflineBanner(),
              if (all.isEmpty)
                const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications yet',
                  body: 'We will let you know when something happens.',
                ),
              if (fresh.isNotEmpty) ...[
                _SectionHeader(
                  title: 'New',
                  action: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: () => _markAllRead(context, ref),
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                for (final n in fresh)
                  _NotificationRow(n, onTap: () => _open(context, ref, n)),
              ],
              if (earlier.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _SectionHeader(title: 'Earlier'),
                for (final n in earlier)
                  _NotificationRow(n, onTap: () => _open(context, ref, n)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.sectionHeading)),
          ?action,
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow(this.n, {required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = formatNotificationTime(n.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: '${n.isRead ? '' : 'Unread. '}${n.title}. $time',
        excludeSemantics: true,
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: _tileSize,
                    height: _tileSize,
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.cream : AppColors.honey,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(_iconFor(n.type), color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: AppTextStyles.bodyMedium),
                        if (n.body != null)
                          Text(n.body!, style: AppTextStyles.body),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: AppTextStyles.fieldLabel.copyWith(
                            color: AppColors.placeholder,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!n.isRead)
                    Container(
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      width: _dotSize,
                      height: _dotSize,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
