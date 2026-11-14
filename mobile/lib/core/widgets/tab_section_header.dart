import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Big tab title with an optional amber 44px "+" action (Prayer wall,
/// Testimonies).
class TabSectionHeader extends StatelessWidget {
  const TabSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Semantic label of the "+" button; the button is hidden when null.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.tabTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          Semantics(
            button: true,
            label: actionLabel,
            child: Material(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.add, color: AppColors.ink),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
