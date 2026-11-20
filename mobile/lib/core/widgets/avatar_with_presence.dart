import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'initials_avatar.dart';
import '../theme/app_gradients.dart';

/// [InitialsAvatar] with an optional online presence dot (amber, 2px white
/// border) at the bottom-right corner.
class AvatarWithPresence extends StatelessWidget {
  const AvatarWithPresence({
    super.key,
    required this.initials,
    this.photoPath,
    this.size = 44,
    this.online = false,
    this.backgroundColor,
  });

  final String initials;
  final String? photoPath;
  final double size;
  final bool online;
  final Color? backgroundColor;

  /// [backgroundColor], or the theme's cream.
  Color get _backgroundColor => backgroundColor ?? AppColors.primarySoft;

  @override
  Widget build(BuildContext context) {
    final dotSize = size >= 44 ? 14.0 : 13.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InitialsAvatar(
            initials: initials,
            photoPath: photoPath,
            size: size,
            backgroundColor: _backgroundColor,
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
