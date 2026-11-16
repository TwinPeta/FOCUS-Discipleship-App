import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

import 'package:flutter/services.dart';

import '../media/upload_policy.dart';

/// Multi-line text input. Bordered by default (new prayer request, share a
/// testimony); set [bordered] to false for the borderless composer body.
class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    this.label,
    required this.controller,
    this.placeholder,
    this.minHeight = 120,
    this.fontSize = 15,
    this.textHeight = 1.4,
    this.bordered = true,
    this.autofocus = false,
    this.onChanged,
    this.focusNode,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String? label;
  final TextEditingController controller;
  final String? placeholder;
  final double minHeight;
  final double fontSize;
  final double textHeight;
  final bool bordered;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      inputFormatters: [
        LengthLimitingTextInputFormatter(UploadPolicy.maxPostChars),
      ],
      focusNode: focusNode,
      autofocus: autofocus,
      maxLines: null,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: AppTextStyles.body.copyWith(
        fontSize: fontSize,
        height: textHeight,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        // The box is drawn around the field; the theme's (dark) input
        // fill and outline must not draw a second one inside it.
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        hintText: placeholder,
        hintStyle: AppTextStyles.body.copyWith(
          fontSize: fontSize,
          height: textHeight,
          color: AppColors.placeholder,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.fieldLabel),
          const SizedBox(height: 6),
        ],
        Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: EdgeInsets.all(bordered ? 14 : 0),
          decoration: bordered
              ? BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                  border: Border.all(color: AppColors.inputBorder, width: 1.5),
                )
              : null,
          child: field,
        ),
      ],
    );
  }
}
