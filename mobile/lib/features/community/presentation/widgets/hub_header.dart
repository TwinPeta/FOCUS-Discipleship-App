import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/count_badge.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../messaging/presentation/providers/messaging_providers.dart';
import '../../../profile/domain/user_profile.dart';

/// Communities hub header (screen 3): "Welcome, Grace" (first name) with the
/// notification bell (unread count) and the profile picture (initials when
/// there is no photo), then the full description on its own line.
class HubHeader extends StatelessWidget {
  const HubHeader({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.fullName.trim().split(RegExp(r'\s+')).first;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.hubHeader,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  // One line, shrinking rather than breaking a word.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Welcome, $firstName',
                      style: AppTextStyles.hubUniversityTitle.copyWith(
                        fontSize: 28,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _ChatsButton(),
              const SizedBox(width: 8),
              const _NotificationBell(),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Open my profile',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: InitialsAvatar(
                    initials: profile.initials,
                    photoPath: profile.photoPath,
                    size: 48,
                    backgroundColor: AppColors.white,
                    borderColor: AppColors.white,
                    borderWidth: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Two ways to belong: the whole campus, and a smaller group with '
            'mentors.',
            style: AppTextStyles.body.copyWith(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Chats, like WhatsApp: the number of unread messages across all
/// conversations (each chat shows its own count in Messages).
class _ChatsButton extends ConsumerWidget {
  const _ChatsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadMessageCountProvider);
    return _HeaderIconButton(
      icon: Icons.chat_bubble_outline_rounded,
      label: unread == 0 ? 'Messages' : 'Messages, $unread unread',
      count: unread,
      onTap: () => context.go('/messages'),
    );
  }
}

/// 48px white circle with an icon and an optional count badge.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: AppColors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Center(child: Icon(icon, color: AppColors.ink)),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: IgnorePointer(child: CountBadge(count: count)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 48px bell; a count badge when there are unread notifications. Opens
/// Notifications (screen 44).
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return _HeaderIconButton(
      icon: Icons.notifications_none_rounded,
      label: unread == 0 ? 'Notifications' : 'Notifications, $unread unread',
      count: unread,
      onTap: () => context.push('/notifications'),
    );
  }
}
