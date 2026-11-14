import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/testimony.dart';

/// One testimony (screen 53), null when not visible to the viewer. The
/// "Encouraged" toggle is optimistic and rolls back on failure.
class TestimonyDetailController
    extends AutoDisposeFamilyAsyncNotifier<Testimony?, String> {
  @override
  Future<Testimony?> build(String id) => ref
      .watch(testimonyRepositoryProvider)
      .getTestimony(id, viewerId: ref.watch(currentProfileProvider)?.id);

  Future<void> toggleEncouraged() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = !current.encouragedByMe;
    state = AsyncData(current.withEncouraged(next));
    try {
      state = AsyncData(
        await ref
            .read(testimonyRepositoryProvider)
            .setEncouraged(current.id, encouraged: next),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final testimonyDetailProvider = AsyncNotifierProvider.autoDispose
    .family<TestimonyDetailController, Testimony?, String>(
      TestimonyDetailController.new,
    );
