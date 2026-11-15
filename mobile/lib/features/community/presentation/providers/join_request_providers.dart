import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../domain/join_request.dart';
import 'membership_provider.dart';

/// Pending join requests for one community (screen 31, and the count on
/// Manage). The repository enforces the super-mentor check with the current
/// role. The server sends the super-mentor no notification or socket event
/// for a new request, so while a screen shows the list it is re-fetched on
/// the notifications poll interval.
final pendingJoinRequestsProvider = FutureProvider.autoDispose
    .family<List<JoinRequest>, String>((ref, communityId) {
      final timer = Timer(
        ref.watch(notificationPollIntervalProvider),
        ref.invalidateSelf,
      );
      ref.onDispose(timer.cancel);
      return ref
          .watch(joinRequestRepositoryProvider)
          .getPending(communityId, actorRole: ref.watch(currentRoleProvider));
    });
