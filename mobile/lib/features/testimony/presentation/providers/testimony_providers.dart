import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../activity/domain/activity_event.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/testimony.dart';
import '../../data/testimony_repository.dart';

class TestimoniesController
    extends FamilyAsyncNotifier<List<Testimony>, String> {
  @override
  Future<List<Testimony>> build(String communityId) {
    final viewerId = ref.watch(currentProfileProvider)?.id;
    return ref
        .watch(testimonyRepositoryProvider)
        .getTestimonies(communityId, viewerId: viewerId);
  }

  /// Optimistic insert as pending; removed again and rethrown on failure.
  Future<void> submitStory(
    Testimony testimony, {
    StoryAttachments attachments = StoryAttachments.none,
  }) async {
    final pending = testimony.withStatus(TestimonyStatus.pending);
    final current = state.valueOrNull ?? const <Testimony>[];
    state = AsyncValue.data([
      pending,
      ...current.where((t) => t.id != pending.id),
    ]);
    try {
      final saved = await ref
          .read(testimonyRepositoryProvider)
          .submitStory(pending, attachments: attachments);
      // The server may assign its own id: swap the stored copy in.
      state = AsyncValue.data([
        for (final t in state.valueOrNull ?? const <Testimony>[])
          t.id == pending.id ? saved : t,
      ]);
    } catch (_) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const <Testimony>[])
            .where((t) => t.id != pending.id)
            .toList(),
      );
      rethrow;
    }
  }

  /// Opening a video testimony counts as watching it (once per video).
  Future<void> openVideo(Testimony testimony) async {
    await ref
        .read(activityRecorderProvider)
        .record(
          ActivityType.videoWatched,
          'Watched "${testimony.title}"',
          sourceId: testimony.id,
        );
  }
}

final testimoniesProvider =
    AsyncNotifierProvider.family<
      TestimoniesController,
      List<Testimony>,
      String
    >(TestimoniesController.new);
