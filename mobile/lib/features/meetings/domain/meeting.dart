/// One weekly community meeting (screen 51).
class Meeting {
  const Meeting({
    required this.id,
    required this.communityId,
    required this.startsAt,
    required this.room,
    this.going = false,
    this.attended = false,
  });

  final String id;
  final String communityId;
  final DateTime startsAt;
  final String room;

  /// The member's RSVP ("I am going").
  final bool going;

  /// The member checked in ("I am here").
  final bool attended;

  Meeting copyWith({bool? going, bool? attended}) => Meeting(
    id: id,
    communityId: communityId,
    startsAt: startsAt,
    room: room,
    going: going ?? this.going,
    attended: attended ?? this.attended,
  );
}

/// The next meeting (still "next" while it runs) and earlier ones, newest
/// first.
class MeetingSchedule {
  const MeetingSchedule({required this.next, required this.past});

  final Meeting? next;
  final List<Meeting> past;
}

/// When "I am here" is allowed: from [opensBefore] the start until
/// [closesAfter] it. The defaults are an assumption; both are configurable.
class CheckInWindow {
  const CheckInWindow({
    this.opensBefore = const Duration(minutes: 30),
    this.closesAfter = const Duration(hours: 2),
  });

  final Duration opensBefore;
  final Duration closesAfter;

  DateTime opensAt(Meeting m) => m.startsAt.subtract(opensBefore);
  DateTime closesAt(Meeting m) => m.startsAt.add(closesAfter);

  bool isOpen(Meeting m, DateTime now) =>
      !now.isBefore(opensAt(m)) && !now.isAfter(closesAt(m));
}

/// Check-in outside the window.
class CheckInClosed implements Exception {
  const CheckInClosed(this.meetingId);
  final String meetingId;
  @override
  String toString() => 'CheckInClosed($meetingId)';
}

/// A second check-in for the same meeting.
class AlreadyCheckedIn implements Exception {
  const AlreadyCheckedIn(this.meetingId);
  final String meetingId;
  @override
  String toString() => 'AlreadyCheckedIn($meetingId)';
}
