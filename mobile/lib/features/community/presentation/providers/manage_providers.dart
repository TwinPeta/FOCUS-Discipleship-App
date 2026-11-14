import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/person.dart';
import 'community_providers.dart';
import 'membership_provider.dart';

/// "No activity for 14+ days" on Manage (screen 30).
const followUpInactivity = Duration(days: 14);

/// Members (not leaders) with no activity within [inactiveFor] of [now],
/// longest-quiet first; members never active come first of all.
List<Person> membersToFollowUp(
  List<Person> members,
  Map<String, DateTime> lastActive, {
  required DateTime now,
  Duration inactiveFor = followUpInactivity,
}) {
  final quiet = members.where((m) {
    if (m.role != PersonRole.member) return false;
    final last = lastActive[m.id];
    return last == null || now.difference(last) >= inactiveFor;
  }).toList();
  DateTime since(Person p) =>
      lastActive[p.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
  quiet.sort((a, b) => since(a).compareTo(since(b)));
  return quiet;
}

/// Injectable clock so the 14-day rule is testable.
final manageClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final membersToFollowUpProvider = FutureProvider.autoDispose
    .family<List<Person>, String>((ref, communityId) async {
      final members = await ref.watch(
        communityMembersProvider(communityId).future,
      );
      final lastActive = await ref
          .watch(activityRepositoryProvider)
          .lastActiveByMember(
            communityId,
            actorRole: ref.watch(currentRoleProvider),
          );
      return membersToFollowUp(
        members,
        lastActive,
        now: ref.watch(manageClockProvider)(),
      );
    });
