import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// 44px flag button that opens a report for a piece of content (comment,
/// prayer request, testimony). [label] is read by screen readers.
class ReportIconButton extends StatelessWidget {
  const ReportIconButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(
        Icons.flag_outlined,
        size: 20,
        color: AppColors.inkDeemphasized80,
      ),
    );
  }
}
