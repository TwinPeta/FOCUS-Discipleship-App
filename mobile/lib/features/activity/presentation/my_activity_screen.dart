import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/dashed_circle_painter.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../domain/activity_event.dart';
import '../domain/badge.dart';
import 'providers/activity_providers.dart';
import '../../../core/theme/app_gradients.dart';

/// Screen 20: My activity & badges.
class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  IconData _iconFor(ActivityType type) => switch (type) {
    ActivityType.videoWatched => Icons.play_circle_outline_rounded,
    ActivityType.devotionalRead => Icons.menu_book_outlined,
    ActivityType.documentRead => Icons.description_outlined,
    ActivityType.quizCompleted => Icons.quiz_outlined,
    ActivityType.prayed => Icons.favorite_border_rounded,
    ActivityType.pathwayCompleted => Icons.flag_outlined,
    ActivityType.meetingAttended => Icons.groups_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesProvider);
    final eventsAsync = ref.watch(activityEventsProvider);
    final events = eventsAsync.valueOrNull ?? const <ActivityEvent>[];

    return AmberHeaderScaffold(
      backFallback: '/profile',
      title: 'My activity',
      subtitle: 'Your journey, only visible to you.',
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverList.list(
              children: [
                const InfoBanner(
                  icon: Icons.lock_outline_rounded,
                  child: Text(
                    'Only you can see this. FCU records your participation to help you follow your growth.',
                  ),
                ),
                const SizedBox(height: 20),
                Text('My badges', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 12),
                badgesAsync.when(
                  loading: () =>
                      const Skeleton(showHeader: false, cardCount: 1),
                  error: (error, stackTrace) =>
                      ErrorView(onRetry: () => ref.invalidate(badgesProvider)),
                  data: (badges) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < badges.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _BadgeItem(badge: badges[i]),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Recent activity', style: AppTextStyles.sectionHeading),
              ],
            ),
          ),
          if (eventsAsync.isLoading && !eventsAsync.hasValue)
            const SliverToBoxAdapter(
              child: Skeleton(showHeader: false, cardCount: 1),
            )
          else if (eventsAsync.hasError && !eventsAsync.hasValue)
            SliverToBoxAdapter(
              child: ErrorView(
                onRetry: () => ref.invalidate(activityEventsProvider),
              ),
            )
          else if (events.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.timeline_rounded,
                title: 'Nothing recorded yet',
                body: 'Your activity will show up here.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: events.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _ActivityRow(
                  event: events[index],
                  icon: _iconFor(events[index].type),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                      gradient: AppGradients.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.star_rounded, color: AppColors.ink),
                  )
                : CustomPaint(
                    painter: const DashedCirclePainter(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.placeholder,
                        size: 20,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: AppTextStyles.fieldLabel.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(event.label, style: AppTextStyles.bodyMedium)),
          Text(
            formatDayLabel(event.at),
            style: AppTextStyles.body.copyWith(
              fontSize: 12.5,
              color: AppColors.inkDeemphasized80,
            ),
          ),
        ],
      ),
    );
  }
}
