import '../../../core/network/api_client.dart';
import '../domain/story_video.dart';
import 'stories_repository.dart';

/// [StoriesRepository] backed by the public landing endpoint (no sign-in).
class RemoteStoriesRepository implements StoriesRepository {
  RemoteStoriesRepository(this._api);

  final ApiClient _api;

  static String _duration(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Future<List<StoryVideo>> getStories() async {
    final json = objectOf(await _api.get('/public/landing'));
    final stories = json?['stories'];
    if (stories is! List) return const [];
    return [
      for (final j in stories.whereType<Map<String, dynamic>>())
        StoryVideo(
          id: j['id'] as String,
          quote: (j['quote'] as String?) ?? '',
          authorName: (j['student_name'] as String?) ?? '',
          institution: (j['institution_name'] as String?) ?? '',
          duration: _duration(j['duration_seconds'] as int?),
          videoUrl: j['video_url'] as String?,
        ),
    ];
  }
}
