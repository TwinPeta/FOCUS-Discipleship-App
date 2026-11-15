import 'package:focus_1/features/landing/data/stories_repository.dart';
import 'package:focus_1/features/landing/domain/story_video.dart';

class FakeStoriesRepository implements StoriesRepository {
  static const _latency = Duration(milliseconds: 400);

  @override
  Future<List<StoryVideo>> getStories() async {
    await Future.delayed(_latency);
    return const [
      StoryVideo(
        id: 'story-1',
        quote: '[Student quote about finding friends]',
        authorName: '[Student name]',
        institution: '[University]',
        duration: '0:45',
      ),
      StoryVideo(
        id: 'story-2',
        quote: '[Student quote about learning]',
        authorName: '[Student name]',
        institution: '[University]',
        duration: '1:10',
      ),
      StoryVideo(
        id: 'story-3',
        quote: '[Student quote about mentorship]',
        authorName: '[Student name]',
        institution: '[High school]',
        duration: '0:55',
      ),
    ];
  }
}
