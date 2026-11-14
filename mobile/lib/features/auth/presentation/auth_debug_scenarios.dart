import '../../../core/debug/debug_scenario.dart';
import '../../../core/providers/repository_providers.dart';
import 'providers/auth_providers.dart';

final authDebugScenarios = <DebugScenario>[
  DebugScenario(
    group: 'Account',
    name: 'Guardian confirms',
    description: 'Your guardian clicks the emailed link; messaging opens up.',
    run: (ref, _) async {
      final session = ref.read(authSessionProvider);
      if (session == null) return 'Not signed in';
      final request = await ref
          .read(authRepositoryProvider)
          .debugConfirmGuardian(session.accountId);
      ref.invalidate(guardianRequestProvider);
      return request == null
          ? 'No guardian request was sent'
          : 'Guardian confirmed';
    },
  ),
  DebugScenario(
    group: 'Account',
    name: 'Sign out',
    description: 'Ends the in-memory session.',
    run: (ref, _) async {
      await ref.read(authControllerProvider.notifier).signOut();
      return 'Signed out';
    },
  ),
];
