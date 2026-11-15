import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_gradients.dart';

/// The amber "New post" button floating over both feeds. Disabled (faded,
/// still visible) while offline.
class ComposeFab extends ConsumerWidget {
  const ComposeFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    return Semantics(
      button: true,
      enabled: online,
      label: online ? 'New post' : 'New post. Posting is paused while offline',
      child: Opacity(
        opacity: online ? 1 : _offlineOpacity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: online ? onPressed : null,
            customBorder: const CircleBorder(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2.5),
                boxShadow: AppShadows.hard(offset: const Offset(3, 3)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: AppColors.ink, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

const _offlineOpacity = 0.45;
