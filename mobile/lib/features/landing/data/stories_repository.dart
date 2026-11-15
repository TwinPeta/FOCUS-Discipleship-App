import '../domain/story_video.dart';

abstract class StoriesRepository {
  Future<List<StoryVideo>> getStories();
}
