import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../../core/debug/debug_scenario.dart';
import '../domain/user_role.dart';
import 'providers/membership_provider.dart';

final communityDebugScenarios = <DebugScenario>[
  DebugScenario(
    group: 'Membership',
    name: 'Approve my request',
    description: 'The super-mentor approves your pending request.',
    run: (ref, context) async {
      await ref.read(membershipProvider.notifier).debugApprove();
      if (context.mounted) unawaited(context.push('/request/approved'));
      return null;
    },
  ),
  DebugScenario(
    group: 'Membership',
    name: 'Decline my request',
    description: 'The super-mentor declines your pending request, with a note.',
    run: (ref, context) async {
      await ref
          .read(membershipProvider.notifier)
          .reject(message: 'Our group is full this semester.');
      if (context.mounted) unawaited(context.push('/request/declined'));
      return null;
    },
  ),
  DebugScenario(
    group: 'Membership',
    name: 'Reset my membership',
    description: 'Back to no specific community.',
    run: (ref, _) async {
      await ref.read(membershipProvider.notifier).clear();
      return 'Membership reset';
    },
  ),
  DebugScenario(
    group: 'Accounts',
    name: 'Use the super-mentor test account',
    description: 'Your role in your approved community becomes super-mentor.',
    run: (ref, _) async {
      ref.read(debugRoleOverrideProvider.notifier).state = UserRole.superMentor;
      return 'Now a super-mentor';
    },
  ),
  DebugScenario(
    group: 'Accounts',
    name: 'Use the student test account',
    description: 'Your role goes back to student.',
    run: (ref, _) async {
      ref.read(debugRoleOverrideProvider.notifier).state = null;
      return 'Now a student';
    },
  ),
];
