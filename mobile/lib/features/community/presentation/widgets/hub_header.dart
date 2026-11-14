import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../profile/domain/user_profile.dart';

class HubHeader extends StatelessWidget {
  const HubHeader({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.fullName.trim().split(RegExp(r'\s+')).first;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'WELCOME, ${firstName.toUpperCase()}',
                  style: AppTextStyles.eyebrow,
                ),
              ),
              const _NotificationBell(),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Open my profile',
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: InitialsAvatar(
                    initials: profile.initials,
                    photoPath: profile.photoPath,
                    size: 48,
                    backgroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.institutionName,
            style: AppTextStyles.hubUniversityTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Two ways to belong: the whole campus, and a smaller group with mentors.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

/// 48px white bell; an ink dot (plus the count in its label) when there
/// are unread notifications. The Notifications screen is prompt 3.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Semantics(
      button: true,
      label: unread == 0 ? 'Notifications' : 'Notifications, $unread unread',
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/notifications'),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.ink,
                ),
                if (unread > 0)
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
