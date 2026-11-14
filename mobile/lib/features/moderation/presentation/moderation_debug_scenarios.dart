import '../../../core/debug/debug_scenario.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../notifications/domain/app_notification.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../data/suspension_repository.dart';
import '../domain/suspension.dart';
import 'moderation_providers.dart';

/// How long the debug suspension lasts.
const _debugSuspensionLength = Duration(days: 7);

final moderationDebugScenarios = <DebugScenario>[
  DebugScenario(
    group: 'Moderation',
    name: 'Receive a moderator warning',
    description: 'A super-mentor warns you; the warning screen opens next.',
    run: (ref, _) async {
      final session = ref.read(authSessionProvider);
      if (session == null) return 'Sign in first';
      final warning = await ref
          .read(warningRepositoryProvider)
          .create(
            userId: session.accountId,
            reason: 'Offensive or inappropriate content',
            preview:
                'This group is a waste of time, nobody here takes '
                'anything seriously.',
          );
      await ref
          .read(notificationRepositoryProvider)
          .add(
            type: NotificationType.moderatorWarning,
            title: 'A moderator sent you a warning',
            targetRoute: '/warning/${warning.id}',
          );
      ref
        ..invalidate(notificationsProvider)
        ..invalidate(myWarningsProvider);
      return null;
    },
  ),
  DebugScenario(
    group: 'Moderation',
    name: 'Suspend my account (7 days)',
    description: 'Stands in for an admin suspension; blocks the whole app.',
    run: (ref, _) async {
      final session = ref.read(authSessionProvider);
      final repo = ref.read(suspensionRepositoryProvider);
      if (session == null) return 'Sign in first';
      if (repo is! FakeSuspensionRepository) return 'Not available';
      repo.debugSuspend(
        session.accountId,
        Suspension(
          reason: 'Repeated breaches of the community charter',
          until: ref.read(guardClockProvider)().add(_debugSuspensionLength),
        ),
      );
      ref.invalidate(suspensionProvider);
      return null;
    },
  ),
];
