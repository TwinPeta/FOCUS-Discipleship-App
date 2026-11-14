import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/initials_avatar.dart';
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
