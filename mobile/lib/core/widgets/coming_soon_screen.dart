import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'round_icon_button.dart';

/// Placeholder for every out-of-scope destination, so navigation never
/// dead-ends. Always offers a working back button.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoundIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/communities'),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        size: 40,
                        color: AppColors.placeholder,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: AppTextStyles.sectionHeading,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coming soon',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
