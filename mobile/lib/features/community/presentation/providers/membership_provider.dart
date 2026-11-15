import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
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
    return ref.watch(membershipRepositoryProvider).getMembership();
  }

  Future<void> _write(Future<Membership> Function() call) async {
    state = AsyncValue.data(await call());
  }

  Future<void> requestToJoin(String communityId) => _write(
    () => ref.read(membershipRepositoryProvider).requestToJoin(communityId),
  );

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

  Future<void> leave() =>
      _write(() => ref.read(membershipRepositoryProvider).leave());

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
