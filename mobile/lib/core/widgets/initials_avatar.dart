import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular (or rounded-square) avatar that shows a photo when [photoPath]
/// is set, otherwise falls back to [initials] on a flat fill.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.photoPath,
    this.size = 40,
    this.backgroundColor = AppColors.cream,
    this.borderColor,
    this.borderWidth = 0,
    this.shape = BoxShape.circle,
  });

  final String initials;
  final String? photoPath;
  final double size;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(size * 0.28)
            : null,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? AppColors.white,
                width: borderWidth,
              )
            : null,
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(photoPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              initials,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
