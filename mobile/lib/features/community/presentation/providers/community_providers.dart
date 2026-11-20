import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../messaging/presentation/providers/moderation_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/community.dart';
import '../../domain/person.dart';

final communityByIdProvider = FutureProvider.family<Community, String>((
  ref,
  id,
) {
  return ref.watch(communityRepositoryProvider).getCommunityById(id);
});

/// The signed-in user's institution id, derived from their profile.
final currentInstitutionIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) return null;
  return ref.watch(profileRepositoryProvider).institutionIdFor(profile);
});

final specificCommunitiesProvider = FutureProvider<List<Community>>((
  ref,
) async {
  final institutionId = ref.watch(currentInstitutionIdProvider);
  if (institutionId == null) return const [];
  return ref
      .watch(communityRepositoryProvider)
      .getSpecificCommunities(institutionId);
});

/// The signed-in user's General community (section 3: `/general-feed`).
final generalCommunityProvider = FutureProvider<Community>((ref) async {
  final profile = ref.watch(currentProfileProvider);
  final institutionId = ref.watch(currentInstitutionIdProvider);
  if (profile == null || institutionId == null) {
    throw StateError('A profile is required to load the General caregroup.');
  }
  return ref
      .watch(communityRepositoryProvider)
      .getGeneralCommunity(institutionId, profile.institutionName);
});

/// Members with blocked users removed.
final communityMembersProvider = FutureProvider.autoDispose
    .family<List<Person>, String>((ref, communityId) async {
      final blocked = await ref.watch(blockedUserIdsProvider.future);
      final members = await ref
          .watch(communityRepositoryProvider)
          .getMembers(communityId);
      return members.where((m) => !blocked.contains(m.id)).toList();
    });
