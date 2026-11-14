import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/membership.dart';

/// The signed-in user's specific-community membership, shared across the
/// Hub, Detail, Profile and Feed screens.
class MembershipController extends AsyncNotifier<Membership> {
  @override
  Future<Membership> build() async {
    return ref.watch(membershipRepositoryProvider).getMembership();
  }

  Future<void> requestToJoin(String communityId) async {
    final repository = ref.read(membershipRepositoryProvider);
    state = AsyncValue.data(await repository.requestToJoin(communityId));
  }

  /// Debug-only prototype hook standing in for real super-mentor approval.
  Future<void> debugApprove() async {
    final repository = ref.read(membershipRepositoryProvider);
    state = AsyncValue.data(await repository.debugApprove());
  }

  Future<void> reject() async {
    final repository = ref.read(membershipRepositoryProvider);
    state = AsyncValue.data(await repository.reject());
  }

  Future<void> clear() async {
    final repository = ref.read(membershipRepositoryProvider);
    state = AsyncValue.data(await repository.clear());
  }
}

final membershipProvider =
    AsyncNotifierProvider<MembershipController, Membership>(
      MembershipController.new,
    );
