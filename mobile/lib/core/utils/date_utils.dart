/// Formats a timestamp as short relative text ("2 hours ago", "Yesterday",
/// "2 days ago"), matching the feed's seeded post captions.
/// [now] is injectable for tests. Future times read as "Just now".
String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(dateTime);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes min${minutes == 1 ? '' : 's'} ago';
  }
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}

/// "Today", "Yesterday", a weekday name, or a short date — used for
/// conversation day separators and the activity log.
String formatDayLabel(DateTime date, {DateTime? clock}) {
  final now = clock ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  if (difference > 1 && difference < 7) return weekdays[date.weekday - 1];
  return '${date.day}/${date.month}/${date.year}';
}

/// Notification row time: "Today · 9:15", "Yesterday", "Mon" (within the
/// last week), otherwise a short date.
String formatNotificationTime(DateTime at, {DateTime? clock}) {
  final now = clock ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(DateTime(at.year, at.month, at.day)).inDays;
  if (days <= 0) {
    final minutes = at.minute.toString().padLeft(2, '0');
    return 'Today · ${at.hour}:$minutes';
  }
  if (days == 1) return 'Yesterday';
  const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (days < 7) return short[at.weekday - 1];
  return '${at.day}/${at.month}/${at.year}';
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

/// "21 November 2026".
String formatLongDate(DateTime d) =>
    '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
