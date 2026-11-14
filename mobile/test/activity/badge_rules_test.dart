import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/activity/data/activity_repository.dart';
import 'package:focus_1/features/activity/domain/activity_event.dart';

void main() {
  test(
    'badge rules: first steps, quiz finisher, prayer partner, pathway complete',
    () async {
      final repo = FakeActivityRepository(latency: Duration.zero);
      DateTime now() => DateTime.now();

      // First steps: earned on the very first event, regardless of type.
      var earned = await repo.record(
        ActivityEvent(
          type: ActivityType.meetingAttended,
          label: 'Attended a meeting',
          at: now(),
        ),
      );
      expect(earned.map((b) => b.id), contains('first-steps'));

      // Never earned a second time.
      earned = await repo.record(
        ActivityEvent(
          type: ActivityType.meetingAttended,
          label: 'Attended a meeting',
          at: now(),
        ),
      );
      expect(earned, isEmpty);

      // Quiz finisher: earned the first time a quiz is completed.
      earned = await repo.record(
        ActivityEvent(
          type: ActivityType.quizCompleted,
          label: 'Completed a quiz',
          at: now(),
        ),
      );
      expect(earned.map((b) => b.id), contains('quiz-finisher'));

      // Prayer partner: earned on the 5th "prayed" event, not before.
      for (var i = 0; i < 4; i++) {
        earned = await repo.record(
          ActivityEvent(
            type: ActivityType.prayed,
            label: 'Prayed for a request',
            at: now(),
          ),
        );
        expect(earned.map((b) => b.id), isNot(contains('prayer-partner')));
      }
      earned = await repo.record(
        ActivityEvent(
          type: ActivityType.prayed,
          label: 'Prayed for a request',
          at: now(),
        ),
      );
      expect(earned.map((b) => b.id), contains('prayer-partner'));

      // Pathway complete: earned when a pathway finishes.
      earned = await repo.record(
        ActivityEvent(
          type: ActivityType.pathwayCompleted,
          label: 'Completed a pathway',
          at: now(),
        ),
      );
      expect(earned.map((b) => b.id), contains('pathway-complete'));

      final badges = await repo.getBadges();
      expect(badges.every((b) => b.earned), isTrue);
    },
  );
}
