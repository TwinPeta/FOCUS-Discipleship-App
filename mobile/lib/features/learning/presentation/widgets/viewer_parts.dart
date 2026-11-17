import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/error_snack.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../pathways/domain/pathway_step.dart';
import '../../domain/learning_models.dart';
import '../learning_providers.dart';

/// Reads `?pathway=` / `?community=` from the viewer route.
LearningOrigin originOf(GoRouterState state) => (
  pathwayId: state.uri.queryParameters['pathway'],
  communityId: state.uri.queryParameters['community'],
);

/// Back to wherever the viewer was opened from (pathway or Resources).
void leaveViewer(BuildContext context, LearningOrigin origin) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  final community = origin.communityId;
  if (community != null && origin.pathwayId != null) {
    context.go('/community/$community/pathways/${origin.pathwayId}');
  } else if (community != null) {
    context.go('/community/$community/resources');
  } else {
    context.go('/communities');
  }
}

/// Opens Badge earned (38) for the first queued badge, if any.
void showQueuedBadges(BuildContext context, WidgetRef ref) {
  final next = ref.read(badgeQueueProvider.notifier).next;
  if (next != null && context.mounted) {
    unawaited(context.push('/badge/${next.id}/earned'));
  }
}

/// Shared viewer layout: optional hero (the video player) or a back row,
/// chips, a 28/w900 title, content, the Next-in-pathway tile and a pinned
/// primary action.
class ViewerScaffold extends StatelessWidget {
  const ViewerScaffold({
    super.key,
    required this.origin,
    required this.title,
    required this.chips,
    required this.content,
    required this.bottom,
    this.hero,
    this.itemId,
    this.headerBelowTitle,
  });

  final LearningOrigin origin;
  final String title;
  final List<Widget> chips;
  final List<Widget> content;
  final Widget bottom;
  final Widget? hero;

  /// Content id; enables the Next-in-pathway tile when opened from one.
  final String? itemId;
  final Widget? headerBelowTitle;

  @override
  Widget build(BuildContext context) {
    final pathwayId = origin.pathwayId;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            ?hero,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (hero == null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Back',
                        onPressed: () => leaveViewer(context, origin),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (chips.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 8, children: chips),
                  const SizedBox(height: 10),
                  Semantics(
                    header: true,
                    child: Text(title, style: AppTextStyles.viewerTitle),
                  ),
                  if (headerBelowTitle != null) ...[
                    const SizedBox(height: 6),
                    headerBelowTitle!,
                  ],
                  const SizedBox(height: 14),
                  ...content,
                  if (pathwayId != null && itemId != null) ...[
                    const SizedBox(height: 16),
                    NextInPathwayTile(
                      pathwayId: pathwayId,
                      currentId: itemId!,
                      communityId: origin.communityId,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.cream)),
              ),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Video" honey chip + optional topic cream chip.
List<Widget> viewerChips(String kindLabel, {String? topic, String? extra}) => [
  AppChip(label: kindLabel, backgroundColor: AppColors.honey),
  if (topic != null) AppChip(label: topic, backgroundColor: AppColors.cream),
  if (extra != null) AppChip(label: extra, backgroundColor: AppColors.cream),
];

/// Cream "Next in pathway" tile; locked until the current step is done.
class NextInPathwayTile extends ConsumerWidget {
  const NextInPathwayTile({
    super.key,
    required this.pathwayId,
    required this.currentId,
    this.communityId,
  });

  final String pathwayId;
  final String currentId;
  final String? communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(
      nextPathwayStepProvider((pathwayId: pathwayId, stepId: currentId)),
    );
    if (next == null) return const SizedBox.shrink();
    final locked = next.status == PathwayStepStatus.locked;
    return Semantics(
      button: true,
      label:
          'Next in pathway: ${next.title}${locked ? ', locked until you finish this step' : ''}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          onTap: () {
            if (locked) {
              showErrorSnack(context, 'Finish this step first.');
              return;
            }
            context.pushReplacement(
              learningRoute(
                kindForStep(next.type),
                next.id,
                pathwayId: pathwayId,
                communityId: communityId,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  locked ? Icons.lock_outline_rounded : Icons.skip_next_rounded,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXT IN PATHWAY', style: AppTextStyles.eyebrow),
                      Text(next.title, style: AppTextStyles.cardTitle),
                      Text(
                        next.meta,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
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

/// Pinned "Mark as complete/read/done": records activity, advances the
/// pathway and shows any badges. Shows "Completed" once done.
class CompleteButton extends ConsumerStatefulWidget {
  const CompleteButton({
    super.key,
    required this.label,
    required this.item,
    required this.origin,
    this.beforeComplete,
  });

  final String label;
  final LearningItem item;
  final LearningOrigin origin;

  /// E.g. saving a reflection first.
  final Future<void> Function()? beforeComplete;

  @override
  ConsumerState<CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends ConsumerState<CompleteButton> {
  bool _busy = false;

  Future<void> _complete() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.beforeComplete?.call();
      final badges = await ref
          .read(learningActionsProvider)
          .complete(widget.item, pathwayId: widget.origin.pathwayId);
      if (!mounted) return;
      if (badges.isNotEmpty) {
        showQueuedBadges(context, ref);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nice work. Saved.')));
      }
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done =
        ref.watch(isCompleteProvider(widget.item.id)).valueOrNull ?? false;
    return AppPrimaryButton(
      label: done ? 'Completed' : widget.label,
      isLoading: _busy,
      onPressed: done ? null : _complete,
    );
  }
}
