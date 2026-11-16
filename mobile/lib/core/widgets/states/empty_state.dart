import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../app_primary_button.dart';

/// "Nothing here yet" state: icon, title, body and an optional amber action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.honey,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.body, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: actionLabel!,
              height: 48,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
