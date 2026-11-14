import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/community.dart';

class CommunityListCard extends StatelessWidget {
  const CommunityListCard({
    super.key,
    required this.community,
    required this.tileColor,
    this.enabled = true,
  });

  final Community community;
  final Color tileColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(community.initials, style: AppTextStyles.cardTitle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: AppTextStyles.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Super-mentor: ${community.superMentor?.name ?? "[Name]"}',
                  style: AppTextStyles.body.copyWith(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (community.meetingDay != null &&
                        community.meetingTime != null)
                      AppChip(
                        label:
                            '${community.meetingDay} · ${community.meetingTime}',
                      ),
                    if (community.room != null)
                      AppChip(
                        label: community.room!,
                        backgroundColor: AppColors.cream,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
        ],
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.5, child: card);
    }

    return Semantics(
      button: true,
      label:
          '${community.name}, ${community.meetingDay ?? ""} ${community.meetingTime ?? ""}',
      child: InkWell(
        onTap: () => context.push('/communities/${community.id}'),
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}
