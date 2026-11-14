import '../../community/domain/community.dart';
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

/// Builds weekly meetings from a community's day, time and room. Only the
/// member's RSVPs and check-ins are stored.
class FakeMeetingRepository implements MeetingRepository {
  FakeMeetingRepository({
    required this.communityById,
    this.latency = const Duration(milliseconds: 300),
    this.window = const CheckInWindow(),
    this.pastCount = 3,
  });

  final Future<Community> Function(String id) communityById;
  final Duration latency;
  @override
  final CheckInWindow window;

  /// How many earlier meetings the list shows.
  final int pastCount;

  final Set<String> _going = {};
  final Set<String> _attended = {};

  /// Seeded history for earlier weeks: attended, missed, attended.
  static const _seedAttended = [true, false, true];

  final Map<String, Meeting> _known = {};
  final Set<String> _seeded = {};
  final Set<String> _inFlight = {};

  @override
  Future<MeetingSchedule> getSchedule(
    String communityId, {
    required DateTime now,
  }) async {
    await Future.delayed(latency);
    final c = await communityById(communityId);
    final start = _nextStart(c, now);
    if (start == null) return const MeetingSchedule(next: null, past: []);
    final room = c.room ?? '';
    final next = _meeting(communityId, start, room);
    final past = [
      for (var i = 1; i <= pastCount; i++)
        _meeting(communityId, start.subtract(Duration(days: 7 * i)), room),
    ];
    if (_seeded.add(communityId)) {
      for (var i = 0; i < past.length && i < _seedAttended.length; i++) {
        if (_seedAttended[i]) _attended.add(past[i].id);
      }
    }
    return MeetingSchedule(
      next: _current(next),
      past: past.map(_current).toList(),
    );
  }

  Meeting _meeting(String communityId, DateTime start, String room) {
    final d = start;
    final id =
        '$communityId@${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    return _known[id] ??= Meeting(
      id: id,
      communityId: communityId,
      startsAt: start,
      room: room,
    );
  }

  Meeting _current(Meeting m) => m.copyWith(
    going: _going.contains(m.id),
    attended: _attended.contains(m.id),
  );

  /// The first weekly start whose check-in window has not closed yet, so a
  /// meeting stays "next" while it runs.
  DateTime? _nextStart(Community c, DateTime now) {
    final weekday = parseWeekday(c.meetingDay);
    final time = parseClockTime(c.meetingTime);
    if (weekday == null || time == null) return null;
    var day = DateTime(now.year, now.month, now.day);
    day = day.subtract(Duration(days: (day.weekday - weekday) % 7));
    var start = DateTime(day.year, day.month, day.day, time.$1, time.$2);
    while (now.isAfter(start.add(window.closesAfter))) {
      start = start.add(const Duration(days: 7));
    }
    return start;
  }

  Meeting _find(String id) {
    final m = _known[id];
    if (m == null) throw ArgumentError.value(id, 'meetingId', 'unknown');
    return m;
  }

  @override
  Future<Meeting> setGoing(String meetingId, {required bool going}) async {
    await Future.delayed(latency);
    final m = _find(meetingId);
    going ? _going.add(m.id) : _going.remove(m.id);
    return _current(m);
  }

  @override
  Future<Meeting> checkIn(String meetingId, {required DateTime now}) async {
    if (!_inFlight.add(meetingId)) throw AlreadyCheckedIn(meetingId);
    try {
      await Future.delayed(latency);
      final m = _find(meetingId);
      if (_attended.contains(m.id)) throw AlreadyCheckedIn(m.id);
      if (!window.isOpen(m, now)) throw CheckInClosed(m.id);
      _attended.add(m.id);
      return _current(m);
    } finally {
      _inFlight.remove(meetingId);
    }
  }
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
