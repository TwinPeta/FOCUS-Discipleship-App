import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_gradients.dart';

/// The "General | specific community" segmented switch shown in every
/// community header.
class ScopeSwitch extends StatelessWidget {
  const ScopeSwitch({
    super.key,
    required this.specificLabel,
    required this.generalSelected,
    required this.onSelectGeneral,
    required this.onSelectSpecific,
  });

  final String specificLabel;
  final bool generalSelected;
  final VoidCallback onSelectGeneral;
  final VoidCallback onSelectSpecific;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'General',
              selected: generalSelected,
              onTap: onSelectGeneral,
            ),
          ),
          Expanded(
            child: _Segment(
              label: specificLabel,
              selected: !generalSelected,
              onTap: onSelectSpecific,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? null : Colors.transparent,
            gradient: AppGradients.when(selected),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.chip.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
