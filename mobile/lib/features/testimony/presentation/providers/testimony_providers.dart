import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/testimony.dart';

class TestimoniesController extends FamilyAsyncNotifier<List<Testimony>, String> {
  @override
  Future<List<Testimony>> build(String communityId) {
    return ref.watch(testimonyRepositoryProvider).getTestimonies(communityId);
  }

  Future<void> submitStory(Testimony testimony) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([testimony, ...current]);
    await ref.read(testimonyRepositoryProvider).submitStory(testimony);
  }
}

final testimoniesProvider =
    AsyncNotifierProvider.family<TestimoniesController, List<Testimony>, String>(
      TestimoniesController.new,
    );
