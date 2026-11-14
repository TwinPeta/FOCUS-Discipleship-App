import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/info_banner.dart';
import '../../activity/domain/activity_event.dart';
import '../../activity/presentation/providers/activity_providers.dart';
import '../domain/testimony.dart';
import 'providers/testimony_providers.dart';

/// Screen 16: Testimonies tab inside [CommunityShell].
class TestimoniesScreen extends ConsumerWidget {
  const TestimoniesScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimoniesAsync = ref.watch(testimoniesProvider(communityId));

    return testimoniesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Could not load testimonies.', style: AppTextStyles.body),
      ),
      data: (testimonies) {
        final hasPendingMine = testimonies.any(
          (t) => t.isMine && t.status == TestimonyStatus.pending,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Text(
                  'Testimonies',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Share your story',
                  child: InkWell(
                    onTap: () => context.push('/community/$communityId/testimonies/new'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.add, color: AppColors.ink),
                    ),
                  ),
                ),
              ],
            ),
            if (hasPendingMine) ...[
              const SizedBox(height: 16),
              InfoBanner(
                icon: Icons.hourglass_top_rounded,
                child: const Text('Your story is awaiting review by the moderators.'),
              ),
            ],
            const SizedBox(height: 16),
            if (testimonies.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No testimonies yet. Be the first to share yours.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (var i = 0; i < testimonies.length; i++) ...[
                testimonies[i].type == TestimonyType.video
                    ? _VideoTestimonyCard(
                        testimony: testimonies[i],
                        onPlay: () async {
                          await ref.read(activityRepositoryProvider).record(
                            ActivityEvent(
                              type: 'video_watched',
                              label: 'Watched "${testimonies[i].title}"',
                              at: DateTime.now(),
                            ),
                          );
                          ref.invalidate(activityEventsProvider);
                          ref.invalidate(badgesProvider);
                        },
                      )
                    : _StoryTestimonyCard(testimony: testimonies[i]),
                if (i != testimonies.length - 1) const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _VideoTestimonyCard extends StatelessWidget {
  const _VideoTestimonyCard({required this.testimony, required this.onPlay});

  final Testimony testimony;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Play ${testimony.title}',
            child: InkWell(
              onTap: () {
                onPlay();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video player coming soon')),
                );
              },
              child: Stack(
                children: [
                  Container(height: 130, width: double.infinity, color: AppColors.amber),
                  const Positioned.fill(
                    child: Center(
                      child: _PlayButton(),
                    ),
                  ),
                  if (testimony.duration != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '[${testimony.duration}]',
                          style: AppTextStyles.chip,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  testimony.title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${testimony.authorName} · ${testimony.institution}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.inkDeemphasized80,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.play_arrow_rounded, color: AppColors.ink, size: 30),
    );
  }
}

class _StoryTestimonyCard extends StatelessWidget {
  const _StoryTestimonyCard({required this.testimony});

  final Testimony testimony;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWithPresence(initials: testimony.authorName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimony.authorName,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                    ),
                    Text(
                      formatRelativeTime(testimony.createdAt),
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.inkDeemphasized80,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: testimony.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            testimony.title,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (testimony.excerpt != null) ...[
            const SizedBox(height: 6),
            Text(
              testimony.excerpt!,
              style: const TextStyle(fontSize: 16, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'Read story',
            child: InkWell(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Full story coming soon')),
              ),
              child: Text(
                'Read story',
                style: AppTextStyles.fieldLabel.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TestimonyStatus status;

  @override
  Widget build(BuildContext context) {
    final reviewed = status == TestimonyStatus.reviewed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reviewed ? Icons.check_circle_outline_rounded : Icons.hourglass_top_rounded,
            size: 13,
            color: AppColors.ink,
          ),
          const SizedBox(width: 4),
          Text(reviewed ? 'Reviewed' : 'Pending review', style: AppTextStyles.chip),
        ],
      ),
    );
  }
}
