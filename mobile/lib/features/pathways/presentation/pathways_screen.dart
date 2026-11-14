import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../domain/pathway.dart';
import 'providers/pathway_providers.dart';

/// Screen 18: Pathways tab inside [CommunityShell].
class PathwaysScreen extends ConsumerWidget {
  const PathwaysScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathwaysAsync = ref.watch(pathwaysProvider);

    return pathwaysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Could not load pathways.', style: AppTextStyles.body),
      ),
      data: (pathways) {
        if (pathways.isEmpty) {
          return Center(
            child: Text('No pathways yet.', style: AppTextStyles.body),
          );
        }
        final firstPathwayId = pathways.first.id;
        bool isLocked(Pathway pathway) {
          if (pathway.unlocksAfterPathwayId == null) return false;
          final prerequisite = pathways.firstWhere(
            (p) => p.id == pathway.unlocksAfterPathwayId,
            orElse: () => pathway,
          );
          return prerequisite.status != PathwayStatus.completed;
        }

        final current = pathways.where((p) => p.status == PathwayStatus.inProgress).firstOrNull ??
            pathways.where((p) => !isLocked(p) && p.status == PathwayStatus.notStarted).firstOrNull;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (current != null) ...[
              _CurrentPathwayCard(pathway: current, communityId: communityId),
              const SizedBox(height: 20),
            ],
            Text(
              'All pathways',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < pathways.length; i++) ...[
              _PathwayRow(
                pathway: pathways[i],
                locked: isLocked(pathways[i]),
                unlocksAfterFirst: pathways[i].unlocksAfterPathwayId == firstPathwayId,
                onTap: () => context.push('/community/$communityId/pathways/${pathways[i].id}'),
              ),
              if (i != pathways.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _CurrentPathwayCard extends StatelessWidget {
  const _CurrentPathwayCard({required this.pathway, required this.communityId});

  final Pathway pathway;
  final String communityId;

  @override
  Widget build(BuildContext context) {
    final progress = pathway.stepCount == 0
        ? 0.0
        : pathway.currentStepIndex / pathway.stepCount;

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
            style: AppTextStyles.cardTitle.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Step ${pathway.currentStepIndex + 1} of ${pathway.stepCount}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0, 1),
                child: Container(color: AppColors.ink),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppSecondaryButton(
            label: 'Continue',
            height: 46,
            onPressed: () => context.push('/community/$communityId/pathways/${pathway.id}'),
          ),
        ],
      ),
    );
  }
}

class _PathwayRow extends StatelessWidget {
  const _PathwayRow({
    required this.pathway,
    required this.locked,
    required this.unlocksAfterFirst,
    required this.onTap,
  });

  final Pathway pathway;
  final bool locked;
  final bool unlocksAfterFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
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
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: row),
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
    final color = status == PathwayStatus.notStarted ? AppColors.cream : AppColors.honey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppTextStyles.chip),
    );
  }
}

extension on Iterable<Pathway> {
  Pathway? get firstOrNull => isEmpty ? null : first;
}
