import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_text_styles.dart';
import 'community_header_chrome.dart';

class FilterChipOption<T> {
  const FilterChipOption({required this.label, required this.value});

  final String label;
  final T value;
}

/// Single-select filter (e.g. All / Videos / Devotionals). No sideways
/// scrolling: the current choice shows as one blue pill and every option
/// sits in the "⋯" menu (the same sheet as the caregroup sections).
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.menuTitle = 'Show',
  });

  final List<FilterChipOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Title of the "⋯" sheet.
  final String menuTitle;

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );
    void open() => showSectionMenu(context, menuTitle, [
      for (final o in options)
        SectionMenuItem(
          label: o.label,
          icon: o.value == value
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          active: o.value == value,
          onSelected: () => onChanged(o.value),
        ),
    ]);
    return Row(
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              current.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.chip.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'More filters',
          excludeSemantics: true,
          child: InkWell(
            onTap: open,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inputBorder, width: 1.5),
              ),
              child: Icon(Icons.more_horiz_rounded, color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}
