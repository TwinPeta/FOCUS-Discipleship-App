import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'sized_file_image.dart';

/// Circular (or rounded-square) avatar that shows a photo when [photoPath]
/// is set, otherwise falls back to [initials] on a flat fill.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.photoPath,
    this.size = 40,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.shape = BoxShape.circle,
  });

  final String initials;
  final String? photoPath;
  final double size;
  final Color? backgroundColor;

  /// [backgroundColor], or the theme's cream.
  Color get _backgroundColor => backgroundColor ?? AppColors.primarySoft;
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
        color: _backgroundColor,
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
                image: sizedFileImage(context, photoPath!, logicalSize: size),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              initials,
              textScaler: TextScaler.noScaling,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
