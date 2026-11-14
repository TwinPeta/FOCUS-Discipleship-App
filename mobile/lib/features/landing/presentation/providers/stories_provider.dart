import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/story_video.dart';

final storiesProvider = FutureProvider<List<StoryVideo>>((ref) async {
  final repository = ref.watch(storiesRepositoryProvider);
  return repository.getStories();
});
