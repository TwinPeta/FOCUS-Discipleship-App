import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../core/realtime/realtime_bindings.dart';
import '../core/router/app_router.dart';
import 'demo_backend.dart';
import 'fakes.dart';

/// Web demo build: `flutter build web --dart-define=DEMO_MODE=true`.
/// Runs entirely on the in-memory sample data, skips sign-up, email
/// verification, consent and join approval, and opens signed in as an
/// approved member of Growth Circle. Never used by the normal build.
const kDemoMode = bool.fromEnvironment('DEMO_MODE');

/// The community the demo member is already approved in.
const demoCommunityId = 'growth-circle';

/// Overrides that put the whole app on sample data with "Demo Student"
/// (`demo@fcu.test` / `Password1234`) signed in and approved in
/// [demoCommunityId]. The debug screen's "Use the super-mentor test
/// account" still works in debug builds.
Future<List<Override>> demoOverrides() async {
  final auth = FakeAuthRepository()
    ..debugSignInAs(FakeAuthRepository.demoEmail);
  final profiles = FakeProfileRepository();
  final notifications = FakeNotificationRepository();
  final memberships = FakeMembershipRepository(
    latency: Duration.zero,
    notifications: notifications,
  );
  await memberships.requestToJoin(demoCommunityId);
  await memberships.debugApprove();
  await memberships.markResultSeen();
  await notifications.markAllRead();

  return [
    ...fakeBackend(),
    authRepositoryProvider.overrideWith((ref) => auth),
    profileRepositoryProvider.overrideWith((ref) => profiles),
    notificationRepositoryProvider.overrideWith((ref) => notifications),
    membershipRepositoryProvider.overrideWith((ref) => memberships),
    // No live server in the demo: no socket, no device registration.
    realtimeBindingsProvider.overrideWith((ref) {}),
    initialLocationProvider.overrideWithValue(
      '/community/$demoCommunityId/feed',
    ),
  ];
}
