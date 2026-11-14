import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// One confirmation dialog for the whole app. Resolves to true only when
/// the user confirms.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(title, style: AppTextStyles.sectionHeading),
      content: Text(message, style: AppTextStyles.body),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(44, 44),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: destructive ? AppColors.error : AppColors.ink,
            minimumSize: const Size(44, 44),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A dialog asking for optional text (e.g. a decline message). Resolves to
/// null when cancelled, otherwise the trimmed text (possibly empty).
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      title: Text(title, style: AppTextStyles.sectionHeading),
      content: TextField(
        controller: controller,
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(44, 44),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(44, 44),
          ),
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
