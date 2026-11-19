import 'package:focus_1/features/community/domain/community.dart';
import 'package:focus_1/features/meetings/data/meeting_repository.dart';
import 'package:focus_1/features/meetings/domain/meeting.dart';

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
