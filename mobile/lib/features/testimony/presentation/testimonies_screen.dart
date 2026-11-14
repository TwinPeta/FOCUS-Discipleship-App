import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/avatar_with_presence.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../../core/widgets/tab_section_header.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/testimony.dart';
import 'providers/testimony_providers.dart';

/// Screen 16: Testimonies tab inside [CommunityShell].
class TestimoniesScreen extends ConsumerWidget {
  const TestimoniesScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = testimoniesProvider(communityId);
    final testimoniesAsync = ref.watch(provider);
    final viewerId = ref.watch(currentProfileProvider)?.id;

    if (testimoniesAsync.isLoading && !testimoniesAsync.hasValue) {
      return const Skeleton(showHeader: false);
    }
    if (testimoniesAsync.hasError && !testimoniesAsync.hasValue) {
      return ErrorView(onRetry: () => ref.invalidate(provider));
    }
    final testimonies = testimoniesAsync.valueOrNull ?? const <Testimony>[];
    final hasPendingMine = testimonies.any(
      (t) => t.isAuthoredBy(viewerId) && t.status == TestimonyStatus.pending,
    );
    void share() => context.push('/community/$communityId/testimonies/new');

    final header = <Widget>[
      TabSectionHeader(
        title: 'Testimonies',
        actionLabel: 'Share your story',
        onAction: share,
      ),
      if (hasPendingMine)
        const InfoBanner(
          icon: Icons.hourglass_top_rounded,
          child: Text('Your story is awaiting review by the moderators.'),
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount:
            header.length + (testimonies.isEmpty ? 1 : testimonies.length),
        itemBuilder: (context, index) {
          if (index < header.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: header[index],
            );
          }
          if (testimonies.isEmpty) {
            return EmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'No testimonies yet',
              body: 'Be the first to share yours.',
              actionLabel: 'Share your story',
              onAction: share,
            );
          }
          final testimony = testimonies[index - header.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: testimony.type == TestimonyType.video
                ? _VideoTestimonyCard(
                    key: ValueKey(testimony.id),
                    testimony: testimony,
                    onPlay: () =>
                        ref.read(provider.notifier).openVideo(testimony),
                  )
                : _StoryTestimonyCard(
                    key: ValueKey(testimony.id),
                    testimony: testimony,
                    onRead: () => context.push('/testimony/${testimony.id}'),
                  ),
          );
        },
      ),
    );
  }
}

class _VideoTestimonyCard extends StatelessWidget {
  const _VideoTestimonyCard({
    super.key,
    required this.testimony,
    required this.onPlay,
  });

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
                  Container(
                    height: 130,
                    width: double.infinity,
                    color: AppColors.amber,
                  ),
                  const Positioned.fill(child: Center(child: _PlayButton())),
                  if (testimony.duration != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
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
      child: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.ink,
        size: 30,
      ),
    );
  }
}

class _StoryTestimonyCard extends StatelessWidget {
  const _StoryTestimonyCard({
    super.key,
    required this.testimony,
    required this.onRead,
  });

  final Testimony testimony;
  final VoidCallback onRead;

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
              AvatarWithPresence(
                initials: initialsOf(testimony.authorName),
                size: 40,
              ),
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
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
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
            excludeSemantics: true,
            child: InkWell(
              onTap: onRead,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Read story',
                  style: AppTextStyles.fieldLabel.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
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
            reviewed
                ? Icons.check_circle_outline_rounded
                : Icons.hourglass_top_rounded,
            size: 13,
            color: AppColors.ink,
          ),
          const SizedBox(width: 4),
          Text(
            reviewed ? 'Reviewed' : 'Pending review',
            style: AppTextStyles.chip,
          ),
        ],
      ),
    );
  }
}
