import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/community/data/membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/profile/data/profile_repository.dart';

import 'pump_utils.dart';

/// Boots the real app (real router, guards and fake repositories) with a
/// signed-in profile and the given membership, at a given screen size and
/// text scale.
Future<ProviderContainer> pumpFcuApp(
  WidgetTester tester, {
  MembershipStatus membership = MembershipStatus.approved,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool signedIn = true,
  bool resultSeen = true,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final auth = FakeAuthRepository(latency: Duration.zero)
    ..debugSeedAccount(testProfile.email, 'Password1234', testProfile.id);
  if (signedIn) auth.debugSignInAs(testProfile.email);
  final profiles = FakeProfileRepository(latency: Duration.zero);
  final memberships = FakeMembershipRepository(latency: Duration.zero);
  await tester.runAsync(() async {
    await profiles.createProfile(testProfile);
    if (membership != MembershipStatus.none) {
      await memberships.requestToJoin('growth-circle');
      if (membership == MembershipStatus.approved) {
        await memberships.debugApprove();
      } else if (membership == MembershipStatus.rejected) {
        await memberships.reject(message: 'Group is full');
      }
      if (resultSeen && membership != MembershipStatus.pending) {
        await memberships.markResultSeen();
      }
    }
  });

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((ref) => auth),
      profileRepositoryProvider.overrideWith((ref) => profiles),
      membershipRepositoryProvider.overrideWith((ref) => memberships),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
  await settle(tester);
  return container;
}

Future<void> goTo(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  container.read(routerProvider).go(location);
  await settle(tester, steps: 12);
}
