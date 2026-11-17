import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The 50px rounded search field used on the hub, the inbox and New
/// message. Turns cream while [enabled] is false.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.placeholder,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.placeholder),
          filled: true,
          fillColor: enabled ? AppColors.white : AppColors.cream,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.ink, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
        ),
      ),
    );
  }
}
