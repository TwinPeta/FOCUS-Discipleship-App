import '../../../core/debug/debug_scenario.dart';
import '../domain/activity_event.dart';
import 'providers/activity_providers.dart';

final activityDebugScenarios = <DebugScenario>[
  DebugScenario(
    group: 'Activity',
    name: 'Record meeting attended',
    description: 'Logs attendance at this week\'s community meeting.',
    run: (ref, _) async {
      final badges = await ref
          .read(activityRecorderProvider)
          .record(ActivityType.meetingAttended, 'Attended a community meeting');
      return [
        'Meeting recorded',
        for (final b in badges) 'New badge: ${b.name}',
      ].join(' · ');
    },
  ),
];
