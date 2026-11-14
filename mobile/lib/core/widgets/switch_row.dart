import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const _minRowHeight = 56.0;

/// A labelled amber switch row (title, optional subtitle). The whole row is
/// the touch target. Used by Notification settings and Settings.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minRowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppTextStyles.bodyMedium),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.placeholder,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.amber,
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: AppColors.skeletonBlock,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    AppColors.inputBorder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
