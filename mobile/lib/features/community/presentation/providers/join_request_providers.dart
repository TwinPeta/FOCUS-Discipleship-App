import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../domain/join_request.dart';
import 'membership_provider.dart';

/// Pending join requests for one community (screen 31, and the count on
/// Manage). The repository enforces the super-mentor check with the current
/// role. A new request arrives as the `join_request.created` socket event;
/// while a screen shows the list it is also re-fetched on the notifications
/// poll interval, in case the socket missed it.
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
