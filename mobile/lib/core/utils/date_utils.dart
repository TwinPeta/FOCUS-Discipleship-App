/// Formats a timestamp as short relative text ("2 hours ago", "Yesterday",
/// "2 days ago"), matching the feed's seeded post captions.
String formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

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
String formatDayLabel(DateTime date) {
  final now = DateTime.now();
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
