import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/route_guards.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/auth/presentation/sign_in_screen.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/moderation/domain/suspension.dart';
import 'package:focus_1/features/moderation/domain/warning.dart';
import 'package:focus_1/features/moderation/presentation/account_suspended_screen.dart';
import 'package:focus_1/features/moderation/presentation/moderation_providers.dart';
import 'package:focus_1/features/moderation/presentation/moderator_warning_screen.dart';
import 'package:focus_1/features/profile/domain/user_profile.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

final _now = DateTime(2026, 11, 14, 12);
final _warning = Warning(
  id: 'warning-1',
  userId: 'u',
  reason: 'Harassment or bullying',
  preview: 'Hidden text',
  createdAt: _now,
);
final _suspension = Suspension(
  reason: 'Repeated breaches',
  until: _now.add(const Duration(days: 3)),
);

GuardContext _ctx(
  String path, {
  bool signedIn = true,
  bool hasProfile = true,
  Warning? warning,
  Suspension? suspension,
  DateTime? now,
}) => GuardContext(
  location: Uri.parse(path),
  profile: AsyncValue<UserProfile?>.data(hasProfile ? testProfile : null),
  membership: const AsyncValue.data(
    Membership(communityId: 'growth-circle', status: MembershipStatus.approved),
  ),
  session: AsyncValue.data(
    signedIn
        ? AuthSession(accountId: testProfile.id, email: testProfile.email)
        : null,
  ),
  pendingWarning: AsyncValue.data(warning),
  suspension: AsyncValue.data(suspension),
  now: now ?? _now,
);

void main() {
  group('guard chain', () {
    test(
      'final order: suspended, warning, signed out, onboarding, membership',
      () {
        expect(defaultGuardChain.map((g) => g.name), [
          'suspended',
          'unacknowledgedWarning',
          'signedOut',
          'onboardingIncomplete',
          'membership',
        ]);
      },
    );

    test('suspension wins over everything, even a pending warning', () {
      final c = _ctx(
        '/community/growth-circle/feed',
        warning: _warning,
        suspension: _suspension,
      );
      expect(runGuards(c), '/suspended');
      expect(
        runGuards(_ctx('/warning/warning-1', suspension: _suspension)),
        '/suspended',
      );
    });

    test('a suspended account may read the charter and help only', () {
      for (final p in ['/suspended', '/charter', '/help']) {
        expect(runGuards(_ctx(p, suspension: _suspension)), isNull, reason: p);
      }
      expect(
        runGuards(_ctx('/messages', suspension: _suspension)),
        '/suspended',
      );
    });

    test('the suspension releases by itself when "until" passes', () {
      final after = _suspension.until.add(const Duration(minutes: 1));
      expect(
        runGuards(_ctx('/communities', suspension: _suspension, now: after)),
        isNull,
      );
      expect(
        runGuards(_ctx('/suspended', suspension: _suspension, now: after)),
        '/communities',
      );
    });

    test('a pending warning comes before signed-in screens and onboarding', () {
      expect(
        runGuards(_ctx('/communities', warning: _warning)),
        '/warning/warning-1',
      );
      expect(
        runGuards(_ctx('/join', hasProfile: false, warning: _warning)),
        '/warning/warning-1',
      );
      expect(runGuards(_ctx('/warning/warning-1', warning: _warning)), isNull);
      expect(runGuards(_ctx('/charter', warning: _warning)), isNull);
    });

    test('signed out: warnings and suspensions do not apply', () {
      final c = _ctx(
        '/login',
        signedIn: false,
        warning: _warning,
        suspension: _suspension,
      );
      expect(runGuards(c), isNull);
      expect(
        runGuards(_ctx('/messages', signedIn: false, warning: _warning)),
        '/',
      );
    });

    test('no warning, no suspension: the old chain decides', () {
      expect(runGuards(_ctx('/communities')), isNull);
      expect(runGuards(_ctx('/suspended')), '/communities');
    });
  });

  testWidgets('screen 61: a warning blocks the app until acknowledged', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await tester.runAsync(
      () => container
          .read(warningRepositoryProvider)
          .create(
            userId: testProfile.id,
            reason: 'Harassment or bullying',
            preview: 'The hidden comment',
          ),
    );
    container.invalidate(myWarningsProvider);
    await goTo(tester, container, '/communities');
    // ignore: avoid_print
    expect(find.byType(ModeratorWarningScreen), findsOneWidget);
    expect(find.text('A moderator sent you a warning'), findsOneWidget);
    expect(
      find.text('Reason: Harassment or bullying. This message was hidden:'),
      findsOneWidget,
    );
    expect(find.text('The hidden comment'), findsOneWidget);

    await tester.tap(find.text('I understand'));
    await settle(tester, steps: 15);
    expect(find.byType(ModeratorWarningScreen), findsNothing);
    final pending = container.read(pendingWarningProvider).valueOrNull;
    expect(pending, isNull);
  });

  testWidgets('screen 60: suspended account sees only the suspension', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    final repo = container.read(
      suspensionRepositoryProvider,
    ) as FakeSuspensionRepository;
    repo.debugSuspend(
      testProfile.id,
      Suspension(
        reason: 'Repeated breaches',
        until: DateTime.now().add(const Duration(days: 3)),
      ),
    );
    container.invalidate(suspensionProvider);
    await goTo(tester, container, '/community/growth-circle/feed');

    expect(find.byType(AccountSuspendedScreen), findsOneWidget);
    expect(find.text('Your account is suspended'), findsOneWidget);
    expect(
      find.textContaining('Reason: Repeated breaches. Until'),
      findsOneWidget,
    );

    await tester.tap(find.text('Sign out'));
    await settle(tester, steps: 15);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  test('formatSuspensionDate', () {
    expect(formatSuspensionDate(DateTime(2026, 11, 21)), '21 November 2026');
  });
}
