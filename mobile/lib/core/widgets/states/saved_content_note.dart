import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../connectivity/connectivity_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../app_chip.dart';

/// Marks a list as saved content while offline (screen 56); hidden online.
class SavedContentNote extends ConsumerWidget {
  const SavedContentNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    if (online) return const SizedBox.shrink();
    return Semantics(
      label: 'Saved content. Showing what you last loaded.',
      excludeSemantics: true,
      child: Row(
        children: [
          const AppChip(label: 'Saved', icon: Icons.download_done_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing what you last loaded.',
              style: AppTextStyles.fieldLabel.copyWith(
                color: AppColors.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
