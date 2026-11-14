import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../domain/moderation_case.dart';
import '../domain/suspension.dart';
import '../domain/warning.dart';

/// Open Level 1 cases for one community (screen 32). The repository
/// enforces the super-mentor check with the current role.
final openModerationCasesProvider = FutureProvider.autoDispose
    .family<List<ModerationCase>, String>((ref, communityId) {
      return ref
          .watch(moderationQueueRepositoryProvider)
          .getOpenCases(communityId, actorRole: ref.watch(currentRoleProvider));
    });

/// The signed-in member's warnings, newest first.
final myWarningsProvider = FutureProvider<List<Warning>>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return const [];
  return ref.watch(warningRepositoryProvider).getWarningsFor(session.accountId);
});

/// The oldest unacknowledged warning; the warning guard shows it (screen
/// 61) before anything else except a suspension.
final pendingWarningProvider = Provider<AsyncValue<Warning?>>((ref) {
  return ref.watch(myWarningsProvider).whenData((all) {
    final pending = all.where((w) => !w.acknowledged).toList();
    return pending.isEmpty ? null : pending.last;
  });
});

/// The signed-in account's suspension (screen 60), active or not.
final suspensionProvider = FutureProvider<Suspension?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return null;
  return ref
      .watch(suspensionRepositoryProvider)
      .getSuspension(session.accountId);
});

/// Injectable clock for time-based guards (suspension end).
final guardClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
