import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';

/// The amber "New post" button floating over both feeds.
class ComposeFab extends StatelessWidget {
  const ComposeFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New post',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.amber,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2.5),
              boxShadow: AppShadows.hard(offset: const Offset(3, 3)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: AppColors.ink, size: 28),
          ),
        ),
      ),
    );
  }
}
