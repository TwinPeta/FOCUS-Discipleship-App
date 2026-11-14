import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/initials_avatar.dart';

class ComposerRow extends StatelessWidget {
  const ComposerRow({
    super.key,
    required this.initials,
    this.photoPath,
    required this.onTap,
  });

  final String initials;
  final String? photoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share something',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              InitialsAvatar(
                initials: initials,
                photoPath: photoPath,
                size: 38,
                backgroundColor: AppColors.cream,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Share something…',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.placeholder,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.videocam_outlined,
                size: 20,
                color: AppColors.placeholder,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.emoji_emotions_outlined,
                size: 20,
                color: AppColors.placeholder,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                size: 20,
                color: AppColors.placeholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
