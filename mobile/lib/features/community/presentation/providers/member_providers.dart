import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../messaging/presentation/providers/moderation_providers.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/member_profile.dart';
import '../../domain/membership.dart';
import '../../domain/person.dart';
import '../../domain/user_role.dart';
import 'community_providers.dart';
import 'membership_provider.dart';

/// The profile at `/members/:id`. The signed-in user's own profile is built
/// from their account (their own badges); everyone else's comes from the
/// member directory, which never exposes activity history.
final memberProfileProvider = FutureProvider.autoDispose
    .family<MemberProfile?, String>((ref, id) async {
      final me = ref.watch(currentProfileProvider);
      if (me != null && me.id == id) {
        final badges = await ref.watch(activityRepositoryProvider).getBadges();
        final membership = ref.watch(membershipProvider).valueOrNull;
        final communityId = membership?.status == MembershipStatus.approved
            ? membership?.communityId
            : null;
        final community = communityId == null
            ? null
            : await ref.watch(communityByIdProvider(communityId).future);
        return MemberProfile(
          person: Person(
            id: me.id,
            name: me.fullName,
            role: switch (ref.watch(currentRoleProvider)) {
              UserRole.superMentor => PersonRole.superMentor,
              UserRole.mentor => PersonRole.mentor,
              _ => PersonRole.member,
            },
          ),
          username: me.username,
          institution: me.institutionName,
          communityName: community?.name,
          badges: badges.where((b) => b.earned).toList(),
        );
      }
      return ref.watch(memberRepositoryProvider).getMember(id);
    });

/// A community's members with usernames, blocked people left out (the
/// repository filters; watching the block list refreshes it).
final communityMemberProfilesProvider = FutureProvider.autoDispose
    .family<List<MemberProfile>, String>((ref, communityId) async {
      await ref.watch(blockedUserIdsProvider.future);
      return ref
          .watch(memberRepositoryProvider)
          .getCommunityMembers(communityId);
    });

/// Screen 55: everyone the user blocked, by name.
final blockedMembersProvider = FutureProvider.autoDispose<List<MemberProfile>>((
  ref,
) async {
  final ids = await ref.watch(blockedUserIdsProvider.future);
  final repo = ref.watch(memberRepositoryProvider);
  final profiles = await Future.wait(ids.map(repo.getMember));
  return [
    for (final (i, id) in ids.indexed)
      profiles[i] ??
          MemberProfile(
            person: Person(id: id, name: 'Member', role: PersonRole.member),
            username: id,
          ),
  ]..sort((a, b) => a.person.name.compareTo(b.person.name));
});
