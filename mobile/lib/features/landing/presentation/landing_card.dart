import '../../../core/config/landing_videos.dart';
import '../../../core/utils/open_link.dart';
import '../domain/story_video.dart';

/// What one landing story card shows and plays.
class LandingCard {
  const LandingCard({
    required this.url,
    required this.title,
    required this.subtitle,
    this.duration,
  });

  /// Always a playable YouTube link.
  final String url;
  final String title;
  final String subtitle;

  /// Shown only for the student's own video (the curated ones have none).
  final String? duration;

  String? get thumbnailUrl {
    final id = youtubeIdOf(url);
    return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  /// The student's own story when its `video_url` is a real YouTube video;
  /// otherwise (missing, or a placeholder such as `cdn.fcu.example/...m3u8`)
  /// a curated video, labelled with that video's own title and channel so a
  /// card never pairs a student's quote with someone else's video.
  static LandingCard forStory(int index, StoryVideo story) {
    final own = story.videoUrl?.trim() ?? '';
    if (youtubeIdOf(own) != null) {
      return LandingCard(
        url: own,
        title: story.quote,
        subtitle: [
          story.authorName,
          story.institution,
        ].where((s) => s.isNotEmpty).join(' · '),
        duration: story.duration.isEmpty ? null : story.duration,
      );
    }
    final curated = LandingVideos.stories[index % LandingVideos.stories.length];
    return LandingCard(
      url: curated.url,
      title: curated.title,
      subtitle: curated.channel,
    );
  }
}
