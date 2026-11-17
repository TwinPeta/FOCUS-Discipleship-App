import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../connectivity/connectivity_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';

/// Shown at the top of content while offline; hidden otherwise.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    if (online) return const SizedBox.shrink();

    final fg = AppColors.isDark ? AppColors.ink : AppColors.white;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          // Dark card in light mode; a warm honey card in dark mode (the
          // inverted cream card glared there).
          color: AppColors.isDark ? AppColors.honey : AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are offline',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: fg,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Showing saved content. Posting is paused.',
                    style: AppTextStyles.body.copyWith(
                      color: fg,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: turn on Data saver to use less data on slow '
                    'connections.',
                    style: AppTextStyles.body.copyWith(
                      color: fg,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.amber,
                minimumSize: const Size(44, 44),
              ),
              onPressed: () => ref.read(connectivityServiceProvider).check(),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
