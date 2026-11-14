import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../domain/pathway.dart';
import 'widgets/pathway_progress_bar.dart';
import 'providers/pathway_providers.dart';

/// Screen 18: Pathways tab inside [CommunityShell].
class PathwaysScreen extends ConsumerWidget {
  const PathwaysScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathwaysAsync = ref.watch(pathwaysProvider);

    if (pathwaysAsync.isLoading && !pathwaysAsync.hasValue) {
      return const Skeleton(showHeader: false);
    }
    if (pathwaysAsync.hasError && !pathwaysAsync.hasValue) {
      return ErrorView(onRetry: () => ref.invalidate(pathwaysProvider));
    }
    final pathways = pathwaysAsync.valueOrNull ?? const <Pathway>[];
    if (pathways.isEmpty) {
      return const EmptyState(
        icon: Icons.route_rounded,
        title: 'No pathways yet',
        body: 'Your mentors will add pathways soon.',
      );
    }
    final firstPathwayId = pathways.first.id;
    final current =
        pathways
            .where((p) => p.status == PathwayStatus.inProgress)
            .firstOrNull ??
        pathways
            .where((p) => !p.locked && p.status == PathwayStatus.notStarted)
            .firstOrNull;
    void open(Pathway p) =>
        context.push('/community/$communityId/pathways/${p.id}');

    final header = <Widget>[
      if (current != null) ...[
        _CurrentPathwayCard(pathway: current, onContinue: () => open(current)),
        const SizedBox(height: 20),
      ],
      Text('All pathways', style: AppTextStyles.sectionHeading),
      const SizedBox(height: 10),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: header.length + pathways.length,
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        final pathway = pathways[index - header.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PathwayRow(
            key: ValueKey(pathway.id),
            pathway: pathway,
            unlocksAfterFirst: pathway.unlocksAfterPathwayId == firstPathwayId,
            onTap: () => open(pathway),
          ),
        );
      },
    );
  }
}

class _CurrentPathwayCard extends StatelessWidget {
  const _CurrentPathwayCard({required this.pathway, required this.onContinue});

  final Pathway pathway;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MY CURRENT PATHWAY', style: AppTextStyles.eyebrow),
          const SizedBox(height: 8),
          Text(
            pathway.title,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Step ${pathway.currentStepIndex + 1} of ${pathway.stepCount}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          PathwayProgressBar(progress: pathway.progress),
          const SizedBox(height: 14),
          AppSecondaryButton(
            label: 'Continue',
            height: 46,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _PathwayRow extends StatelessWidget {
  const _PathwayRow({
    super.key,
    required this.pathway,
    required this.unlocksAfterFirst,
    required this.onTap,
  });

  final Pathway pathway;
  final bool unlocksAfterFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = pathway.locked;
    final row = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.honey,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              locked ? Icons.lock_outline_rounded : Icons.route_rounded,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pathway.title,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  locked
                      ? '${pathway.stepCount} steps · ${unlocksAfterFirst ? 'Unlocks after the first pathway' : 'Unlocks later'}'
                      : '${pathway.stepCount} steps',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    color: AppColors.inkDeemphasized80,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!locked) ...[
            const SizedBox(width: 8),
            _StatusPill(status: pathway.status),
          ],
        ],
      ),
    );

    if (locked) {
      return Opacity(opacity: 0.55, child: row);
    }
    return Semantics(
      button: true,
      label: pathway.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: row,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final PathwayStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      PathwayStatus.inProgress => 'In progress',
      PathwayStatus.completed => 'Completed',
      PathwayStatus.notStarted => 'Start',
    };
    final color = status == PathwayStatus.notStarted
        ? AppColors.cream
        : AppColors.honey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.chip),
    );
  }
}
