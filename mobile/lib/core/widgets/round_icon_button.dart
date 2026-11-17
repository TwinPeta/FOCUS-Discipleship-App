import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// 44x44 white circular icon button used for back/edit/camera/messages
/// actions. Always carries a semantic label for screen readers.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = 44,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.iconColor,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;

  /// [backgroundColor], or the theme's white.
  Color get _backgroundColor => backgroundColor ?? AppColors.white;
  final Color? borderColor;
  final double borderWidth;
  final Color? iconColor;

  /// [iconColor], or the theme's ink.
  Color get _iconColor => iconColor ?? AppColors.ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: _backgroundColor,
        shape: CircleBorder(
          side: borderWidth > 0
              ? BorderSide(
                  color: borderColor ?? AppColors.ink,
                  width: borderWidth,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: _iconColor, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}
