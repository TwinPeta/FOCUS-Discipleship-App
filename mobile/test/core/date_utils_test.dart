import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/utils/date_utils.dart';

void main() {
  final now = DateTime(2026, 11, 14, 12);

  group('formatRelativeTime', () {
    String f(Duration ago) => formatRelativeTime(now.subtract(ago), now: now);

    test('under a minute and future times', () {
      expect(f(const Duration(seconds: 30)), 'Just now');
      expect(
        formatRelativeTime(now.add(const Duration(hours: 1)), now: now),
        'Just now',
      );
    });
    test('minutes and hours, singular and plural', () {
      expect(f(const Duration(minutes: 1)), '1 min ago');
      expect(f(const Duration(minutes: 59)), '59 mins ago');
      expect(f(const Duration(hours: 1)), '1 hour ago');
      expect(f(const Duration(hours: 23)), '23 hours ago');
    });
    test('days', () {
      expect(f(const Duration(days: 1)), 'Yesterday');
      expect(f(const Duration(days: 5)), '5 days ago');
    });
  });

  group('formatDayLabel', () {
    test('today, yesterday, weekday, date', () {
      expect(formatDayLabel(now, clock: now), 'Today');
      expect(formatDayLabel(DateTime(2026, 11, 13), clock: now), 'Yesterday');
      expect(formatDayLabel(DateTime(2026, 11, 10), clock: now), 'Tuesday');
      expect(formatDayLabel(DateTime(2026, 10, 1), clock: now), '1/10/2026');
    });
  });
}
