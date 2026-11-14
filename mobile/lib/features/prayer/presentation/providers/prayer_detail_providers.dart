import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/prayer_request.dart';
import '../../domain/prayer_response.dart';

/// One prayer request by id (screen 52); null when missing or hidden. Live
/// "I prayed" state comes from the community's wall controller.
final prayerRequestByIdProvider = FutureProvider.autoDispose
    .family<PrayerRequest?, String>((ref, id) {
      return ref.watch(prayerRepositoryProvider).getRequest(id);
    });

/// Responses on a request, oldest first. A new response is appended only
/// once stored, never optimistically, so the anonymous author's own reply
/// never shows their name, not even for a frame.
class PrayerResponsesController
    extends AutoDisposeFamilyAsyncNotifier<List<PrayerResponse>, String> {
  @override
  Future<List<PrayerResponse>> build(String requestId) =>
      ref.watch(prayerRepositoryProvider).getResponses(requestId);

  Future<void> add(String text) async {
    final me = ref.read(currentProfileProvider);
    if (me == null) throw StateError('Not signed in');
    final saved = await ref
        .read(prayerRepositoryProvider)
        .addResponse(
          requestId: arg,
          body: text,
          authorId: me.id,
          authorName: me.fullName,
        );
    state = AsyncData([...?state.valueOrNull, saved]);
  }
}

final prayerResponsesProvider = AsyncNotifierProvider.autoDispose
    .family<PrayerResponsesController, List<PrayerResponse>, String>(
      PrayerResponsesController.new,
    );
