import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_gradients.dart';

class GeneralCommunityCard extends StatelessWidget {
  const GeneralCommunityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'General community, joined automatically, open to all',
      child: InkWell(
        onTap: () => context.push('/general-feed'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.public_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text('General\ncommunity', style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text(
                'Joined · Open',
                style: AppTextStyles.body.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
