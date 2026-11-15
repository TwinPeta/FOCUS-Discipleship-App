import '../utils/open_link.dart';

/// One curated video for the landing page (screen 1).
class CuratedVideo {
  const CuratedVideo(this.url, this.title, this.channel);

  final String url;
  final String title;
  final String channel;
}

/// Videos for the landing page: Christian-centred youth empowerment and
/// collaboration. They play in the app (`/watch`). The hero "play" button
/// uses [featured]; student story cards use their own backend `video_url`
/// and fall back to [stories] in order.
///
/// Each was checked on 2026-11-15 via YouTube oEmbed: it exists and can be
/// embedded. The team should still review the content and may replace these
/// with FOCUS Uganda's own videos.
class LandingVideos {
  LandingVideos._();

  static const featured = CuratedVideo(
    'https://www.youtube.com/watch?v=vFwNZNyDu9k',
    'What is BibleProject?',
    'BibleProject',
  );

  static const stories = [
    CuratedVideo(
      'https://www.youtube.com/watch?v=ZrOwUVdn8co',
      "We're Mobilizing 1000 Young People for 2024 Missions to Uganda",
      'Life Missions',
    ),
    CuratedVideo(
      'https://www.youtube.com/watch?v=8Tbcofs6l3o',
      'What is The Bible Project?',
      'BibleProject',
    ),
    CuratedVideo(
      'https://www.youtube.com/watch?v=Vm1yEXM9u8w',
      'Harvesters Africa Empowerment Foundation Scholarship',
      'HarvestersTV',
    ),
  ];

  /// The story's own link when it is a real YouTube video, else a curated
  /// one (the backend's demo stories carry placeholder links).
  static String forStory(int index, String? fromBackend) {
    final url = fromBackend?.trim() ?? '';
    return youtubeIdOf(url) != null ? url : stories[index % stories.length].url;
  }
}
