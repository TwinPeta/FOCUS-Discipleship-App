import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FilterChipOption<T> {
  const FilterChipOption({required this.label, required this.value});

  final String label;
  final T value;
}

/// Horizontally-scrolling single-select pill row (e.g. All / Videos /
/// Devotionals), 40px high. Selected = amber + w800, unselected = white with
/// a 1.5px [AppColors.inputBorder] outline.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<FilterChipOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = option.value == value;
          return Semantics(
            button: true,
            selected: selected,
            label: option.label,
            child: InkWell(
              onTap: () => onChanged(option.value),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.amber : AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: selected
                      ? null
                      : Border.all(color: AppColors.inputBorder, width: 1.5),
                ),
                child: Text(
                  option.label,
                  style: AppTextStyles.chip.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
