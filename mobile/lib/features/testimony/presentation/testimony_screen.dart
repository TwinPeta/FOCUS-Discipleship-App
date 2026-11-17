import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../messaging/domain/report.dart';
import '../../messaging/presentation/content_report_screens.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/testimony.dart';
import '../../feed/presentation/widgets/post_photo_view.dart';
import 'providers/testimony_detail_providers.dart';
import 'widgets/story_video.dart';

/// Screen 53: Testimony (`/testimony/:id`). Others only ever open reviewed
/// stories; a pending one opens only for its author.
class TestimonyScreen extends ConsumerWidget {
  const TestimonyScreen({super.key, required this.testimonyId});

  final String testimonyId;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(testimonyDetailProvider(testimonyId).notifier)
          .toggleEncouraged();
    } catch (_) {
      if (context.mounted) showErrorSnack(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(testimonyDetailProvider(testimonyId));
    final t = async.valueOrNull;
    final reviewed = t?.status == TestimonyStatus.reviewed;
    return AmberHeaderScaffold(
      title: 'Testimony',
      headerAction: t == null
          ? null
          : AppChip(
              label: reviewed ? 'Reviewed' : 'Pending review',
              icon: reviewed ? Icons.verified_rounded : Icons.schedule_rounded,
              backgroundColor: AppColors.white,
            ),
      body: switch (async) {
        AsyncValue(isLoading: true, hasValue: false) => const Skeleton(
          showHeader: false,
          cardCount: 1,
        ),
        AsyncValue(hasError: true, hasValue: false) => ErrorView(
          onRetry: () => ref.invalidate(testimonyDetailProvider(testimonyId)),
        ),
        _ when t == null => const EmptyState(
          icon: Icons.auto_stories_outlined,
          title: 'Story not available',
          body:
              'It is waiting for review, was removed, or is not visible '
              'to you.',
        ),
        _ => _Body(t: t, onEncourage: () => _toggle(context, ref)),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.t, required this.onEncourage});

  final Testimony t;
  final VoidCallback onEncourage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final mine = t.isAuthoredBy(ref.watch(currentProfileProvider)?.id);
    final encouraged = t.encouragedCount == 1
        ? '1 person encouraged'
        : '${t.encouragedCount} people encouraged';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const OfflineBanner(),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title, style: AppTextStyles.viewerTitle),
              const SizedBox(height: 6),
              Text(
                '${t.authorName} · ${t.institution}',
                style: AppTextStyles.bodyMedium,
              ),
              if (t.videoUrl != null) ...[
                const SizedBox(height: 14),
                StoryVideo(testimony: t),
              ],
              if (t.excerpt case final text? when text.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(text, style: AppTextStyles.body.copyWith(height: 1.6)),
              ],
              for (final photo in t.photos)
                if (postPhotoView(context, photo) case final image?) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                    child: AspectRatio(aspectRatio: 4 / 3, child: image),
                  ),
                ],
            ],
          ),
        ),
        // Only published stories take "Encouraged" (the server refuses the
        // author's own story while it waits for review).
        if (t.status == TestimonyStatus.reviewed) ...[
          const SizedBox(height: 16),
          Semantics(
            toggled: t.encouragedByMe,
            child: t.encouragedByMe
                ? AppPrimaryButton(
                    label: 'Encouraged',
                    height: 48,
                    onPressed: online ? onEncourage : null,
                  )
                : AppSecondaryButton(
                    label: 'Encouraged',
                    icon: Icons.favorite_border_rounded,
                    height: 48,
                    onPressed: online ? onEncourage : null,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            encouraged,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.placeholder,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (!mine) ...[
          const SizedBox(height: 16),
          AppSecondaryButton(
            label: 'Report',
            icon: Icons.flag_outlined,
            height: 48,
            onPressed: () => unawaited(
              context.push(
                contentReportLocation(
                  type: ReportTargetType.testimony,
                  id: t.id,
                  authorId: t.authorId,
                  authorName: t.authorName,
                  communityId: t.communityId,
                  preview: t.excerpt ?? t.title,
                  back: '/testimony/${t.id}',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
