import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/activity/domain/activity_event.dart';
import 'package:focus_1/features/community/domain/community.dart';
import 'package:focus_1/features/meetings/data/meeting_repository.dart';
import 'package:focus_1/features/meetings/domain/meeting.dart';
import 'package:focus_1/features/learning/presentation/badge_earned_screen.dart';
import 'package:focus_1/features/meetings/presentation/meeting_providers.dart';
import 'package:focus_1/features/meetings/presentation/meetings_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

const _community = Community(
  id: 'c',
  name: 'Growth Circle',
  initials: 'GC',
  type: CommunityType.specific,
  institutionId: '',
  description: '',
  meetingDay: 'Every Tuesday',
  meetingTime: '5:00 PM',
  room: 'Room 204',
);

// Tuesday 17 November 2026, 17:00 is the meeting in this week.
final _start = DateTime(2026, 11, 17, 17);

FakeMeetingRepository _repo({CheckInWindow window = const CheckInWindow()}) =>
    FakeMeetingRepository(
      communityById: (_) async => _community,
      latency: Duration.zero,
      window: window,
    );

void main() {
  group('parsing', () {
    test('weekday and clock time', () {
      expect(parseWeekday('Every Tuesday'), DateTime.tuesday);
      expect(parseWeekday('Sunday'), DateTime.sunday);
      expect(parseWeekday('soon'), isNull);
      expect(parseClockTime('5:00 PM'), (17, 0));
      expect(parseClockTime('6:30 pm'), (18, 30));
      expect(parseClockTime('12:15 AM'), (0, 15));
      expect(parseClockTime('09:05'), (9, 5));
      expect(parseClockTime('late'), isNull);
    });
  });

  group('schedule', () {
    test(
      'next meeting stays "next" while it runs, then moves a week',
      () async {
        final repo = _repo();
        Future<DateTime?> next(DateTime now) async =>
            (await repo.getSchedule('c', now: now)).next?.startsAt;
        expect(await next(DateTime(2026, 11, 16, 9)), _start); // Monday
        expect(await next(_start.add(const Duration(hours: 1))), _start);
        expect(
          await next(_start.add(const Duration(hours: 2, minutes: 1))),
          _start.add(const Duration(days: 7)),
        );
      },
    );

    test('past meetings: newest first with seeded attended/missed', () async {
      final s = await _repo().getSchedule('c', now: DateTime(2026, 11, 16));
      expect(s.past.map((m) => m.startsAt), [
        _start.subtract(const Duration(days: 7)),
        _start.subtract(const Duration(days: 14)),
        _start.subtract(const Duration(days: 21)),
      ]);
      expect(s.past.map((m) => m.attended), [true, false, true]);
    });

    test('RSVP is stored and idempotent', () async {
      final repo = _repo();
      final s = await repo.getSchedule('c', now: DateTime(2026, 11, 16));
      await repo.setGoing(s.next!.id, going: true);
      await repo.setGoing(s.next!.id, going: true);
      var again = await repo.getSchedule('c', now: DateTime(2026, 11, 16));
      expect(again.next!.going, isTrue);
      await repo.setGoing(s.next!.id, going: false);
      again = await repo.getSchedule('c', now: DateTime(2026, 11, 16));
      expect(again.next!.going, isFalse);
    });
  });

  group('check-in window (injected clock)', () {
    late FakeMeetingRepository repo;
    late Meeting m;

    setUp(() async {
      repo = _repo();
      m = (await repo.getSchedule('c', now: DateTime(2026, 11, 16))).next!;
    });

    test('closed before 30 minutes ahead and after 2 hours', () async {
      await expectLater(
        repo.checkIn(m.id, now: _start.subtract(const Duration(minutes: 31))),
        throwsA(isA<CheckInClosed>()),
      );
      await expectLater(
        repo.checkIn(
          m.id,
          now: _start.add(const Duration(hours: 2, seconds: 1)),
        ),
        throwsA(isA<CheckInClosed>()),
      );
    });

    test('open at the edges; one check-in per meeting', () async {
      final at = _start.subtract(const Duration(minutes: 30));
      expect((await repo.checkIn(m.id, now: at)).attended, isTrue);
      await expectLater(
        repo.checkIn(m.id, now: at),
        throwsA(isA<AlreadyCheckedIn>()),
      );
      final other = _repo();
      final m2 = (await other.getSchedule(
        'c',
        now: DateTime(2026, 11, 16),
      )).next!;
      expect(
        (await other.checkIn(
          m2.id,
          now: _start.add(const Duration(hours: 2)),
        )).attended,
        isTrue,
      );
    });

    test('a double tap checks in once', () async {
      final slow = FakeMeetingRepository(
        communityById: (_) async => _community,
        latency: const Duration(milliseconds: 10),
      );
      final mm = (await slow.getSchedule(
        'c',
        now: DateTime(2026, 11, 16),
      )).next!;
      final first = slow.checkIn(mm.id, now: _start);
      await expectLater(
        slow.checkIn(mm.id, now: _start),
        throwsA(isA<AlreadyCheckedIn>()),
      );
      expect((await first).attended, isTrue);
    });

    test('the window is configurable', () async {
      final narrow = _repo(
        window: const CheckInWindow(
          opensBefore: Duration(minutes: 5),
          closesAfter: Duration(minutes: 10),
        ),
      );
      final mm = (await narrow.getSchedule(
        'c',
        now: DateTime(2026, 11, 16),
      )).next!;
      await expectLater(
        narrow.checkIn(mm.id, now: _start.subtract(const Duration(minutes: 6))),
        throwsA(isA<CheckInClosed>()),
      );
    });
  });

  test('formatters', () {
    expect(formatMeetingTime(DateTime(2026, 1, 1, 17)), '5:00 PM');
    expect(formatMeetingTime(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(formatMeetingDay(_start), 'Tuesday 17 November 2026');
  });

  testWidgets('screen: RSVP, check-in records attendance and a badge', (
    tester,
  ) async {
    // Pinned to the start of Growth Circle's Tuesday 5:00 PM meeting.
    final container = await pumpFcuApp(
      tester,
      overrides: [meetingClockProvider.overrideWithValue(() => _start)],
    );
    await goTo(tester, container, '/community/growth-circle/meetings');

    expect(find.byType(MeetingsScreen), findsOneWidget);
    expect(find.text('Tuesday 17 November 2026 · 5:00 PM'), findsOneWidget);
    expect(find.text('Room 204, Student Centre'), findsOneWidget);
    expect(find.text('Attended'), findsNWidgets(2));
    expect(find.text('Missed'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'I am going'));
    await settle(tester);
    expect(find.widgetWithText(ElevatedButton, 'I am going'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'I am here'));
    await settle(tester, steps: 15);
    // First activity ever: the "First steps" badge opens screen 38.
    expect(find.byType(BadgeEarnedScreen), findsOneWidget);
    final activity = container.read(activityRepositoryProvider);
    late List<ActivityEvent> events;
    await tester.runAsync(() async => events = await activity.getEvents());
    expect(events.single.type, ActivityType.meetingAttended);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('You are checked in'), findsOneWidget);
  });

  testWidgets('screen: check-in is disabled outside the window', (
    tester,
  ) async {
    final container = await pumpFcuApp(
      tester,
      overrides: [
        meetingClockProvider.overrideWithValue(
          () => _start.subtract(const Duration(hours: 3)),
        ),
      ],
    );
    await goTo(tester, container, '/community/growth-circle/meetings');
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'I am here'),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text('Check-in opens 30 minutes before the meeting starts.'),
      findsOneWidget,
    );
  });
}
