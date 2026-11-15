import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/config/landing_videos.dart';
import 'package:focus_1/core/router/route_guards.dart';
import 'package:focus_1/core/utils/open_link.dart';
import 'package:focus_1/features/landing/domain/story_video.dart';
import 'package:focus_1/features/landing/presentation/landing_card.dart';

void main() {
  test('youtubeIdOf reads the common YouTube link shapes', () {
    const id = 'vFwNZNyDu9k';
    for (final url in [
      'https://www.youtube.com/watch?v=$id',
      'https://youtube.com/watch?feature=share&v=$id',
      'https://youtu.be/$id',
      'https://www.youtube.com/embed/$id',
      'https://www.youtube.com/shorts/$id',
    ]) {
      expect(youtubeIdOf(url), id, reason: url);
    }
    expect(youtubeIdOf('https://vimeo.com/123456'), isNull);
    expect(youtubeIdOf('https://www.youtube.com/@bibleproject'), isNull);
  });

  test('watchRoute encodes the link and title', () {
    final route = Uri.parse(
      watchRoute('https://youtu.be/vFwNZNyDu9k', title: 'A & B'),
    );
    expect(route.path, '/watch');
    expect(route.queryParameters['url'], 'https://youtu.be/vFwNZNyDu9k');
    expect(route.queryParameters['title'], 'A & B');
  });

  test('the player is public, like the landing page', () {
    expect(isPublic('/watch'), isTrue);
  });

  test('curated videos are all playable in-app', () {
    for (final v in [LandingVideos.featured, ...LandingVideos.stories]) {
      expect(youtubeIdOf(v.url), isNotNull, reason: v.url);
    }
  });

  test("a story's own link wins; otherwise curated links in order", () {
    expect(
      LandingVideos.forStory(0, 'https://youtu.be/abcdefghijk'),
      'https://youtu.be/abcdefghijk',
    );
    expect(LandingVideos.forStory(0, null), LandingVideos.stories[0].url);
    expect(LandingVideos.forStory(1, '  '), LandingVideos.stories[1].url);
    // The live API's demo stories carry placeholder links.
    expect(
      LandingVideos.forStory(2, 'https://cdn.fcu.example/stories/story.m3u8'),
      LandingVideos.stories[2].url,
    );
    expect(
      LandingVideos.forStory(LandingVideos.stories.length, null),
      LandingVideos.stories[0].url,
    );
  });

  group('LandingCard', () {
    StoryVideo story(String? url) => StoryVideo(
      id: 's1',
      quote: 'I found my people here',
      authorName: 'Esther N.',
      institution: 'Makerere University',
      duration: '2:10',
      videoUrl: url,
    );

    test('a placeholder link shows and plays a curated video instead', () {
      final card = LandingCard.forStory(
        0,
        story('https://cdn.fcu.example/stories/story.m3u8'),
      );
      expect(card.url, LandingVideos.stories[0].url);
      expect(card.title, LandingVideos.stories[0].title);
      expect(card.subtitle, LandingVideos.stories[0].channel);
      expect(card.duration, isNull, reason: 'no fake duration');
      expect(card.thumbnailUrl, contains('img.youtube.com/vi/'));
    });

    test("a real YouTube link keeps the student's own story", () {
      final card = LandingCard.forStory(
        0,
        story('https://youtu.be/vFwNZNyDu9k'),
      );
      expect(card.url, 'https://youtu.be/vFwNZNyDu9k');
      expect(card.title, 'I found my people here');
      expect(card.subtitle, 'Esther N. · Makerere University');
      expect(card.duration, '2:10');
      expect(
        card.thumbnailUrl,
        'https://img.youtube.com/vi/vFwNZNyDu9k/hqdefault.jpg',
      );
    });
  });
}
