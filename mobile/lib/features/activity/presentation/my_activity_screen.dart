import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/dashed_circle_painter.dart';
import '../../../core/widgets/info_banner.dart';
import '../domain/activity_event.dart';
import '../domain/badge.dart';
import 'providers/activity_providers.dart';

/// Screen 20: My activity & badges.
class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  IconData _iconFor(String type) => switch (type) {
    'video_watched' => Icons.play_circle_outline_rounded,
    'quiz_completed' => Icons.quiz_outlined,
    'prayed' => Icons.favorite_border_rounded,
    'pathway_completed' => Icons.flag_outlined,
    'meeting_attended' => Icons.groups_outlined,
    _ => Icons.timeline_rounded,
  };

  Future<void> _recordMeetingAttended(BuildContext context, WidgetRef ref) async {
    final newlyEarned = await recordActivity(
      ref,
      ActivityEvent(
        type: 'meeting_attended',
        label: 'Attended a community meeting',
        at: DateTime.now(),
      ),
    );
    if (!context.mounted) return;
    for (final badge in newlyEarned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New badge earned: ${badge.name}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesProvider);
    final eventsAsync = ref.watch(activityEventsProvider);

    return AmberHeaderScaffold(
      title: 'My activity',
      subtitle: 'Your journey, only visible to you.',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoBanner(
            icon: Icons.lock_outline_rounded,
            child: const Text(
              'Only you can see this. FCU records your participation to help you follow your growth.',
            ),
          ),
          const SizedBox(height: 20),
          Text('My badges', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 12),
          badgesAsync.when(
            loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) => Text('Could not load badges.', style: AppTextStyles.body),
            data: (badges) => SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _BadgeItem(badge: badges[index]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent activity', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 12),
          eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Could not load activity.', style: AppTextStyles.body),
            data: (events) {
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nothing recorded yet. Your activity will show up here.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < events.length; i++) ...[
                    _ActivityRow(event: events[i], icon: _iconFor(events[i].type)),
                    if (i != events.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _recordMeetingAttended(context, ref),
                child: const Text(
                  'Prototype: record meeting attended',
                  style: TextStyle(decoration: TextDecoration.underline, color: AppColors.ink),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({required this.badge});

  final AppBadge badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Opacity(
            opacity: badge.earned ? 1 : 0.6,
            child: badge.earned
                ? Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.star_rounded, color: AppColors.ink),
                  )
                : CustomPaint(
                    painter: const DashedCirclePainter(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.placeholder, size: 20),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: AppTextStyles.fieldLabel.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event, required this.icon});

  final ActivityEvent event;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(event.label, style: AppTextStyles.bodyMedium),
          ),
          Text(
            formatDayLabel(event.at),
            style: AppTextStyles.body.copyWith(fontSize: 12.5, color: AppColors.inkDeemphasized80),
          ),
        ],
      ),
    );
  }
}
