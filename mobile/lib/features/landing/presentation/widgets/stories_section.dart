import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/landing_videos.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/open_link.dart';
import '../../domain/story_video.dart';
import '../providers/stories_provider.dart';
import 'bold_style.dart';
import 'student_face_painter.dart';

const List<Color> _artBackgrounds = [
  AppColors.amber,
  AppColors.honey,
  AppColors.cream,
];

class StoriesSection extends ConsumerWidget {
  const StoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              'Hear it from students',
              style: AppTextStyles.landingSectionH2,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              'Short video stories from students like you.',
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            // 250 art + text block; the text part grows with text scale.
            height: 322 + MediaQuery.textScalerOf(context).scale(70),
            child: storiesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.ink),
              ),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Could not load stories.',
                  style: AppTextStyles.body,
                ),
              ),
              data: (stories) {
                if (stories.isEmpty) {
                  return Center(
                    child: Text('No stories yet.', style: AppTextStyles.body),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 24),
                  itemCount: stories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return _StoryCard(
                      story: stories[index],
                      videoUrl: LandingVideos.forStory(
                        index,
                        stories[index].videoUrl,
                      ),
                      artBackground:
                          _artBackgrounds[index % _artBackgrounds.length],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.artBackground,
    required this.videoUrl,
  });

  final StoryVideo story;

  /// The story's own video, or a curated fallback.
  final String videoUrl;
  final Color artBackground;

  void _playTapped(BuildContext context) =>
      openVideo(context, videoUrl, title: story.quote);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: boldCardDecoration(color: AppColors.white, radius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Play video: ${story.quote}',
            child: GestureDetector(
              onTap: () => _playTapped(context),
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: artBackground),
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size(202, 202),
                          painter: StudentFacePainter(
                            fillColor: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.ink,
                        size: 28,
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Text(
                          '[${story.duration}]',
                          style: AppTextStyles.chip,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.quote,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${story.authorName} · ${story.institution}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.inkDeemphasized80,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
