import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/initials_avatar.dart';

/// Top of a feed: "Share something…" (a post, with an optional photo) and
/// shortcuts for a question and a prayer request. All open the Create screen
/// for [target] ('general' or a community id). Paused while offline.
class ComposerRow extends ConsumerWidget {
  const ComposerRow({
    super.key,
    required this.initials,
    this.photoPath,
    required this.target,
  });

  final String initials;
  final String? photoPath;
  final String target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    void create(String type) => context.push('/create?type=$type&to=$target');

    Widget shortcut(IconData icon, String label, String type) => IconButton(
      tooltip: label,
      onPressed: () => create(type),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 22, color: AppColors.inkDeemphasized80),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          InitialsAvatar(
            initials: initials,
            photoPath: photoPath,
            size: 38,
            backgroundColor: AppColors.primarySoft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: online
                  ? 'New post'
                  : 'New post. It is sent when you are back online',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => create('post'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    online ? 'Share something…' : 'Share something (sent later)…',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.placeholder,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          shortcut(Icons.help_outline_rounded, 'Ask a question', 'question'),
          shortcut(
            Icons.volunteer_activism_outlined,
            'Prayer request',
            'prayer',
          ),
        ],
      ),
    );
  }
}
