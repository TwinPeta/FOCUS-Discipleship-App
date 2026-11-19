import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/realtime/realtime_bindings.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/notification_providers.dart';
import 'community_providers.dart';
import '../../domain/membership.dart';
import '../../domain/user_role.dart';

/// The signed-in user's specific-community membership, shared across the
/// Hub, Detail, Profile and Feed screens. Rule enforcement lives in the
/// repository; failed writes leave the current state untouched and rethrow.
class MembershipController extends AsyncNotifier<Membership> {
  @override
  Future<Membership> build() async {
    final membership = await ref
        .watch(membershipRepositoryProvider)
        .getMembership();
    // The `join_request.decided` socket event refreshes this at once; while
    // a request is pending it is also re-checked on the notifications poll
    // interval, so a decision missed by the socket (app in the background,
    // socket reconnecting) still shows up.
    if (membership.status == MembershipStatus.pending &&
        !ref.watch(realtimeConnectedProvider)) {
      final timer = Timer(
        ref.watch(notificationPollIntervalProvider),
        ref.invalidateSelf,
      );
      ref.onDispose(timer.cancel);
    }
    // Moving from pending to decided (seen by the poll, a push or the socket) must also refresh the community pages,
    // which carry their own copy of "pending" and would otherwise keep showing it.
    final before = state.valueOrNull;
    if (before != null &&
        before.status == MembershipStatus.pending &&
        membership.status != MembershipStatus.pending) {
      final id = before.communityId;
      if (id != null) ref.invalidate(communityByIdProvider(id));
      ref.invalidate(specificCommunitiesProvider);
    }
    return membership;
  }

  Future<void> _write(Future<Membership> Function() call) async {
    state = AsyncValue.data(await call());
  }

  /// Community details and the specific list carry the caller's
  /// `membership_status` / `can_request` and member counts.
  void _refreshCommunities(String? communityId) {
    if (communityId != null) ref.invalidate(communityByIdProvider(communityId));
    ref.invalidate(specificCommunitiesProvider);
  }

  Future<void> requestToJoin(String communityId) async {
    try {
      await _write(
        () => ref.read(membershipRepositoryProvider).requestToJoin(communityId),
      );
    } on MembershipLimitReached {
      // The server knows a request or membership this state does not:
      // show the real one, then let the screen explain.
      ref.invalidateSelf();
      rethrow;
    }
    _refreshCommunities(communityId);
  }

  /// Withdraws the pending request (`DELETE /join-requests/{id}`).
  Future<void> cancelRequest() async {
    final communityId = state.valueOrNull?.communityId;
    await _write(() => ref.read(membershipRepositoryProvider).cancelRequest());
    _refreshCommunities(communityId);
  }

  /// Debug-only prototype hook standing in for real super-mentor approval.
  Future<void> debugApprove() async {
    await _write(() => ref.read(membershipRepositoryProvider).debugApprove());
    ref.invalidate(notificationsProvider);
  }

  Future<void> reject({String? message}) async {
    await _write(
      () => ref.read(membershipRepositoryProvider).reject(message: message),
    );
    ref.invalidate(notificationsProvider);
  }

  Future<void> leave() async {
    final communityId = state.valueOrNull?.communityId;
    await _write(() => ref.read(membershipRepositoryProvider).leave());
    _refreshCommunities(communityId);
  }

  Future<void> markResultSeen() =>
      _write(() => ref.read(membershipRepositoryProvider).markResultSeen());

  Future<void> clear() =>
      _write(() => ref.read(membershipRepositoryProvider).clear());
}

final membershipProvider =
    AsyncNotifierProvider<MembershipController, Membership>(
      MembershipController.new,
    );

/// Debug-only override for the current user's role (the debug registry's
/// "super-mentor test account" switch). Null means "use the real role".
final debugRoleOverrideProvider = StateProvider<UserRole?>((ref) => null);

/// The user's role in their approved specific community, or null when they
/// have none. Anyone not named as a leader of the community is a student.
final currentRoleProvider = Provider<UserRole?>((ref) {
  final membership = ref.watch(membershipProvider).valueOrNull;
  if (membership == null || membership.status != MembershipStatus.approved) {
    return null;
  }
  final override = ref.watch(debugRoleOverrideProvider);
  if (override != null) return override;
  // Leaders are named on the community itself.
  final communityId = membership.communityId;
  final me = ref.watch(authSessionProvider)?.accountId;
  if (communityId != null && me != null) {
    final community = ref.watch(communityByIdProvider(communityId)).valueOrNull;
    if (community?.superMentor?.id == me) return UserRole.superMentor;
    if (community != null && community.mentors.any((m) => m.id == me)) {
      return UserRole.mentor;
    }
  }
  return UserRole.student;
});
