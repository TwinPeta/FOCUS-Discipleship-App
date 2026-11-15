import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/bold_button.dart';
import 'bold_style.dart';
import '../../../../core/theme/app_gradients.dart';

class FinalCtaSection extends StatelessWidget {
  const FinalCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: boldCardDecoration(
          color: AppColors.amber,
          radius: 28,
        ).copyWith(gradient: AppGradients.brand),
        child: Column(
          children: [
            Text(
              'Ready to meet your people?',
              style: AppTextStyles.landingFinalCtaH2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Changing Students, Transforming Societies.',
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            BoldButton(
              label: 'Explore communities',
              onPressed: () => context.push('/join'),
            ),
          ],
        ),
      ),
    );
  }
}
