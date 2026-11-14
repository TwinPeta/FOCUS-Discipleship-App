import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/join_request.dart';
import 'membership_provider.dart';

/// Pending join requests for one community (screen 31). The repository
/// enforces the super-mentor check with the current role.
final pendingJoinRequestsProvider = FutureProvider.autoDispose
    .family<List<JoinRequest>, String>((ref, communityId) {
      return ref
          .watch(joinRequestRepositoryProvider)
          .getPending(communityId, actorRole: ref.watch(currentRoleProvider));
    });
