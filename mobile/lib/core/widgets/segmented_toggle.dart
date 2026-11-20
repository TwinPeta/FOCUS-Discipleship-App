import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_gradients.dart';

/// Two-option track (e.g. University / High school) with a sliding amber
/// selected pill on a cream background.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 44,
  });

  final List<SegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option.value == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected ? null : Colors.transparent,
                  gradient: AppGradients.selected(selected),
                  borderRadius: BorderRadius.circular((height - 8) / 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label,
                  style: AppTextStyles.chip.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.onPrimary : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SegmentedOption<T> {
  const SegmentedOption({required this.label, required this.value});

  final String label;
  final T value;
}
