import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/meeting_dates.dart';
import '../../../community/domain/community.dart';

/// "Next meeting · Tuesday 18 November · 5:00 PM · Room 204" under the
/// composer. Opens Meetings.
class NextMeetingCard extends StatelessWidget {
  const NextMeetingCard({super.key, required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final next = nextMeetingDate(
      community.meetingDay,
      community.meetingTime,
      DateTime.now(),
    );
    final when = [
      next == null ? community.meetingDay! : dayMonthLabel(next),
      ?community.meetingTime,
    ].join(' · ');
    final where = community.room;
    return Semantics(
      button: true,
      label: 'Next meeting, $when${where == null ? '' : ', $where'}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/community/${community.id}/meetings'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.honey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.event_rounded, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next meeting',
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: AppColors.inkDeemphasized80,
                        ),
                      ),
                      Text(when, style: AppTextStyles.cardTitle),
                      if (where != null)
                        Text(
                          where,
                          style: AppTextStyles.body.copyWith(fontSize: 13.5),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
