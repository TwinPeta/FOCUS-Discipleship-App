import '../domain/meeting.dart';

abstract class MeetingRepository {
  /// When check-in is allowed; the screen reads the same rule.
  CheckInWindow get window;

  /// The community's next meeting and its earlier ones, relative to [now].
  Future<MeetingSchedule> getSchedule(
    String communityId, {
    required DateTime now,
  });

  /// Sets the member's RSVP. Idempotent.
  Future<Meeting> setGoing(String meetingId, {required bool going});

  /// Records "I am here". Throws [CheckInClosed] outside the window and
  /// [AlreadyCheckedIn] on a second check-in (one per meeting).
  Future<Meeting> checkIn(String meetingId, {required DateTime now});
}

const _weekdays = {
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

/// "Every Tuesday" -> [DateTime.tuesday].
int? parseWeekday(String? text) {
  final lower = text?.toLowerCase() ?? '';
  for (final e in _weekdays.entries) {
    if (lower.contains(e.key)) return e.value;
  }
  return null;
}

/// "5:00 PM" -> (17, 0); "6:30 pm" -> (18, 30).
(int, int)? parseClockTime(String? text) {
  final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$')
      .firstMatch(text ?? '');
  if (m == null) return null;
  var hour = int.parse(m.group(1)!);
  final minute = int.parse(m.group(2)!);
  final suffix = m.group(3)?.toLowerCase();
  if (suffix == 'pm' && hour != 12) hour += 12;
  if (suffix == 'am' && hour == 12) hour = 0;
  return (hour, minute);
}
