import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../activity/domain/activity_event.dart';
import '../../activity/domain/badge.dart';
import '../../activity/presentation/providers/activity_providers.dart';
import '../domain/meeting.dart';

/// Injectable clock for the check-in window (screen 51).
final meetingClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// One community's meetings. Writes go through the repository, which
/// enforces the window and one check-in per meeting.
class MeetingScheduleController
    extends FamilyAsyncNotifier<MeetingSchedule, String> {
  @override
  Future<MeetingSchedule> build(String communityId) => ref
      .watch(meetingRepositoryProvider)
      .getSchedule(communityId, now: ref.read(meetingClockProvider)());

  void _replace(Meeting updated) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(
      MeetingSchedule(
        next: s.next?.id == updated.id ? updated : s.next,
        past: [for (final m in s.past) m.id == updated.id ? updated : m],
      ),
    );
  }

  Future<void> setGoing(Meeting m, bool going) async {
    _replace(m.copyWith(going: going));
    try {
      _replace(
        await ref.read(meetingRepositoryProvider).setGoing(m.id, going: going),
      );
    } catch (_) {
      _replace(m);
      rethrow;
    }
  }

  /// Checks in and records the attendance; returns badges newly earned.
  Future<List<AppBadge>> checkIn(Meeting m, {required String label}) async {
    final updated = await ref
        .read(meetingRepositoryProvider)
        .checkIn(m.id, now: ref.read(meetingClockProvider)());
    _replace(updated);
    return ref
        .read(activityRecorderProvider)
        .record(ActivityType.meetingAttended, label, sourceId: m.id);
  }
}

final meetingScheduleProvider =
    AsyncNotifierProvider.family<
      MeetingScheduleController,
      MeetingSchedule,
      String
    >(MeetingScheduleController.new);
