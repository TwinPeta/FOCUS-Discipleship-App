import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// Three bars showing progress through a multi-step flow (the Join form).
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? null : AppColors.primarySoft,
                gradient: AppGradients.selected(isActive),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
