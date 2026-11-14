import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../domain/moderation_case.dart';

/// Open Level 1 cases for one community (screen 32). The repository
/// enforces the super-mentor check with the current role.
final openModerationCasesProvider = FutureProvider.autoDispose
    .family<List<ModerationCase>, String>((ref, communityId) {
      return ref
          .watch(moderationQueueRepositoryProvider)
          .getOpenCases(communityId, actorRole: ref.watch(currentRoleProvider));
    });
