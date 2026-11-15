import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../update/app_update.dart';
import '../utils/open_link.dart';

/// "Update available" strip shown at the top of Home and the hub when a
/// newer Android test build is on GitHub Releases. "Download" opens the APK
/// in the browser; Android then offers to install it over this one.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(appUpdateProvider).valueOrNull;
    if (update == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.amberLight,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: AppColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'A new version of FCU is ready (build ${update.buildNumber}).',
                style: AppTextStyles.bodyMedium,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size(44, 44),
              ),
              onPressed: () => openExternalLink(context, update.downloadUrl),
              child: const Text(
                'Download',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
