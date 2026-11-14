import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activity/presentation/activity_debug_scenarios.dart';
import '../../features/auth/presentation/auth_debug_scenarios.dart';
import '../../features/community/presentation/community_debug_scenarios.dart';
import '../../features/moderation/presentation/moderation_debug_scenarios.dart';
import '../../features/notifications/presentation/notification_debug_scenarios.dart';
import '../../features/pathways/presentation/pathway_debug_scenarios.dart';
import '../connectivity/connectivity_service.dart';
import 'debug_scenario.dart';

final _connectivityScenarios = <DebugScenario>[
  DebugScenario(
    group: 'Connectivity',
    name: 'Go offline',
    description: 'Shows the offline banner and pauses posting.',
    run: (ref, _) async {
      final service = ref.read(connectivityServiceProvider);
      if (service is FakeConnectivityService) service.setOnline(false);
      return 'Offline';
    },
  ),
  DebugScenario(
    group: 'Connectivity',
    name: 'Back online',
    description: 'Hides the offline banner.',
    run: (ref, _) async {
      final service = ref.read(connectivityServiceProvider);
      if (service is FakeConnectivityService) service.setOnline(true);
      return 'Online';
    },
  ),
];

/// Every registered scenario, grouped in display order.
final debugScenariosProvider = Provider<List<DebugScenario>>(
  (ref) => [
    ...authDebugScenarios,
    ...communityDebugScenarios,
    ...pathwayDebugScenarios,
    ...activityDebugScenarios,
    ...notificationDebugScenarios,
    ...moderationDebugScenarios,
    ..._connectivityScenarios,
  ],
);
