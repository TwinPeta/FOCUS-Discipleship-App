import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/router/route_guards.dart';
import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/core/widgets/states/error_view.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/community/data/membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/profile/data/profile_repository.dart';
import 'package:focus_1/features/profile/domain/user_profile.dart';

import '../support/pump_utils.dart';

GuardContext _ctx(
  String location, {
  UserProfile? profile,
  Membership membership = Membership.empty,
  bool loading = false,
}) => GuardContext(
  location: Uri.parse(location),
  profile: loading
      ? const AsyncValue<UserProfile?>.loading()
      : AsyncValue.data(profile),
  membership: AsyncValue.data(membership),
  session: AsyncValue.data(
    profile == null
        ? null
        : AuthSession(accountId: profile.id, email: profile.email),
  ),
);

const _approved = Membership(
  communityId: 'growth-circle',
  status: MembershipStatus.approved,
);

void main() {
  group('runGuards', () {
    test('public routes never redirect', () {
      for (final path in ['/', '/join', '/login', '/help']) {
        expect(runGuards(_ctx(path)), isNull, reason: path);
      }
    });

    test('signed out -> landing for protected routes', () {
      expect(runGuards(_ctx('/communities')), '/');
      expect(runGuards(_ctx('/messages/thread-1')), '/');
    });

    test('community routes require approval in that exact community', () {
      const pending = Membership(
        communityId: 'growth-circle',
        status: MembershipStatus.pending,
      );
      expect(
        runGuards(
          _ctx(
            '/community/growth-circle/feed',
            profile: testProfile,
            membership: pending,
          ),
        ),
        '/communities',
      );
      expect(
        runGuards(
          _ctx(
            '/community/other/feed',
            profile: testProfile,
            membership: _approved,
          ),
        ),
        '/communities',
      );
      expect(
        runGuards(
          _ctx(
            '/community/growth-circle/prayer/new',
            profile: testProfile,
            membership: _approved,
          ),
        ),
        isNull,
      );
    });

    test('while loading, protected routes wait on /loading and come back', () {
      final wait = runGuards(
        _ctx('/community/growth-circle/feed', loading: true),
      );
      expect(wait, startsWith('/loading?from='));
      final back = runGuards(
        _ctx(wait!, profile: testProfile, membership: _approved),
      );
      expect(back, '/community/growth-circle/feed');
    });

    test('guards run in order and the first redirect wins', () {
      final chain = [const _AlwaysTo('/first'), const _AlwaysTo('/second')];
      expect(
        runGuards(_ctx('/x', profile: testProfile), guards: chain),
        '/first',
      );
    });
  });

  group('router', () {
    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      required Membership membership,
    }) async {
      final auth = FakeAuthRepository(latency: Duration.zero)
        ..debugSeedAccount(testProfile.email, 'Password1234', testProfile.id)
        ..debugSignInAs(testProfile.email);
      final profiles = FakeProfileRepository(latency: Duration.zero);
      final memberships = FakeMembershipRepository(latency: Duration.zero);
      // Real async for seeding: fake-async test zones never fire timers
      // that nobody pumps.
      await tester.runAsync(() async {
        await profiles.createProfile(testProfile);
        if (membership.status != MembershipStatus.none) {
          await memberships.requestToJoin(membership.communityId!);
          if (membership.status == MembershipStatus.approved) {
            await memberships.debugApprove();
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
              theme: AppTheme.light(),
              routerConfig: ref.watch(routerProvider),
            ),
          ),
        ),
      );
      await settle(tester);
      return container;
    }

    String location(ProviderContainer c) => c
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

    testWidgets('a deep link to a feed without approval lands on the hub', (
      tester,
    ) async {
      final c = await pumpApp(tester, membership: Membership.empty);
      c.read(routerProvider).go('/community/growth-circle/feed');
      await settle(tester, steps: 20);
      expect(location(c), '/communities');
    });

    testWidgets('an unknown route shows the error view', (tester) async {
      final c = await pumpApp(tester, membership: _approved);
      c.read(routerProvider).go('/definitely/not/a/route');
      await settle(tester);
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('a locked pathway cannot be opened by deep link', (
      tester,
    ) async {
      final c = await pumpApp(tester, membership: _approved);
      c.read(routerProvider).go('/community/growth-circle/pathways/pathway-3');
      await settle(tester, steps: 20);
      expect(find.text('This pathway is locked'), findsOneWidget);
    });
  });
}

class _AlwaysTo extends RouteGuard {
  const _AlwaysTo(this.target);
  final String target;
  @override
  String get name => target;
  @override
  String? redirect(GuardContext context) => target;
}
