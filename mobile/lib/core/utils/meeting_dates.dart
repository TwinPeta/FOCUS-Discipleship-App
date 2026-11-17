// Next-meeting dates from a community's weekly meeting ("Every
// Tuesday", "5:00 PM"), for Community detail and the feed card.

const _weekdayNames = {
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

/// The next meeting from "Every Tuesday" / "Tuesday" and "5:00 PM": today
/// if it has not started yet, otherwise the next such weekday. Null when
/// the day is unknown.
DateTime? nextMeetingDate(String? day, String? time, DateTime now) {
  if (day == null) return null;
  final lower = day.toLowerCase();
  int? weekday;
  for (final e in _weekdayNames.entries) {
    if (lower.contains(e.key)) weekday = e.value;
  }
  if (weekday == null) return null;
  var minutes = 24 * 60; // unknown time: today still counts
  final m = RegExp(
    r'(\d{1,2}):(\d{2})\s*([AP]M)?',
    caseSensitive: false,
  ).firstMatch(time ?? '');
  if (m != null) {
    var h = int.parse(m.group(1)!);
    final pm = m.group(3)?.toUpperCase() == 'PM';
    if (m.group(3) != null) h = h % 12 + (pm ? 12 : 0);
    minutes = h * 60 + int.parse(m.group(2)!);
  }
  final today = DateTime(now.year, now.month, now.day);
  var ahead = (weekday - now.weekday) % 7;
  if (ahead == 0 && now.hour * 60 + now.minute >= minutes) ahead = 7;
  return today.add(Duration(days: ahead));
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// "Tuesday 18 November".
String dayMonthLabel(DateTime d) =>
    '${_dayNames[d.weekday - 1]} ${d.day} ${_monthNames[d.month - 1]}';
