import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/route_guards.dart';
import 'package:focus_1/core/utils/password_policy.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/auth/domain/otp_verifier.dart';
import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/messaging/data/messaging_repository.dart';
import 'package:focus_1/features/profile/data/profile_repository.dart';
import 'package:focus_1/features/profile/domain/user_profile.dart';

import '../support/pump_utils.dart';

Consent _consent({bool charter = true, bool participation = true}) => Consent(
  charterAccepted: charter,
  participationAccepted: participation,
  mentorContactAllowed: false,
  acceptedAt: DateTime(2026),
);

void main() {
  group('password rules', () {
    test('length and letter+number', () {
      expect(PasswordPolicy.isValid('short1'), isFalse);
      expect(PasswordPolicy.isValid('onlyletters'), isFalse);
      expect(PasswordPolicy.isValid('1234567890'), isFalse);
      expect(PasswordPolicy.isValid('letters1234'), isTrue);
    });

    test('the sign-up draft keeps a digest, never the password', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(signUpControllerProvider.notifier).setPassword('letters1234');
      final digest = c.read(signUpControllerProvider).passwordDigest!;
      expect(digest, isNot(contains('letters1234')));
      expect(digest, fakePasswordDigest('letters1234'));
      expect(
        () => c.read(signUpControllerProvider.notifier).setPassword('weak'),
        throwsArgumentError,
      );
    });
  });

  group('email code', () {
    late DateTime now;
    late OtpVerifier otp;
    setUp(() {
      now = DateTime(2026, 11, 14, 12);
      otp = OtpVerifier(clock: () => now)..issue('123456');
    });

    test('wrong codes count down, then a 10-minute lock', () {
      for (var left = 4; left >= 1; left--) {
        final r = otp.verify('000000');
        expect(r.status, OtpStatus.wrong);
        expect(r.attemptsLeft, left);
      }
      final locked = otp.verify('000000');
      expect(locked.status, OtpStatus.locked);
      // Even the right code is refused while locked.
      expect(otp.verify('123456').status, OtpStatus.locked);
      now = now.add(const Duration(minutes: 10));
      expect(otp.verify('123456').status, OtpStatus.verified);
    });

    test('a new code only after the 30s cooldown', () {
      expect(otp.resendAvailableIn, isNotNull);
      expect(() => otp.issue('654321'), throwsStateError);
      now = now.add(const Duration(seconds: 30));
      expect(otp.resendAvailableIn, isNull);
      otp.issue('654321');
      expect(otp.verify('654321').status, OtpStatus.verified);
    });
  });

  group('auth repository', () {
    FakeAuthRepository repo() => FakeAuthRepository(latency: Duration.zero);

    test(
      'sign-in errors are identical for unknown email and wrong password',
      () async {
        final r = repo();
        Object? unknown;
        Object? wrong;
        try {
          await r.signIn('nobody@fcu.test', 'whatever123');
        } catch (e) {
          unknown = e;
        }
        try {
          await r.signIn(FakeAuthRepository.demoEmail, 'wrongpass123');
        } catch (e) {
          wrong = e;
        }
        expect(unknown, isA<InvalidCredentials>());
        expect(wrong, isA<InvalidCredentials>());
        expect(unknown.toString(), wrong.toString());
        final session = await r.signIn(
          FakeAuthRepository.demoEmail,
          FakeAuthRepository.demoPassword,
        );
        expect(session.accountId, FakeAuthRepository.demoAccountId);
      },
    );

    test(
      'password reset completes the same way for known and unknown emails',
      () async {
        final r = repo();
        await expectLater(r.requestPasswordReset('nobody@fcu.test'), completes);
        await expectLater(
          r.requestPasswordReset(FakeAuthRepository.demoEmail),
          completes,
        );
        expect(r.resetRequests, [FakeAuthRepository.demoEmail]);
      },
    );

    test(
      'an account needs a verified email and both required consents',
      () async {
        final r = repo();
        const email = 'new@fcu.test';
        final digest = fakePasswordDigest('letters1234');
        expect(
          () => r.createAccount(
            email: email,
            passwordDigest: digest,
            consent: _consent(),
          ),
          throwsA(isA<SignUpIncomplete>()),
        );
        await r.sendVerificationCode(email);
        await r.verifyCode(email, FakeAuthRepository.fakeCode);
        for (final consent in [
          _consent(charter: false),
          _consent(participation: false),
        ]) {
          expect(consent.isValid, isFalse);
          expect(
            () => r.createAccount(
              email: email,
              passwordDigest: digest,
              consent: consent,
            ),
            throwsA(isA<SignUpIncomplete>()),
          );
        }
        final session = await r.createAccount(
          email: email,
          passwordDigest: digest,
          consent: _consent(),
        );
        expect(session.email, email);
      },
    );

    test("the guardian's email must differ from the student's", () async {
      final r = repo();
      expect(
        () => r.submitGuardianRequest(
          'a1',
          const GuardianRequest(
            guardianName: 'Ruth',
            guardianEmail: 'Me@Example.com',
            relationship: 'Parent',
          ),
          ownEmail: 'me@example.com',
        ),
        throwsA(isA<GuardianEmailInvalid>()),
      );
    });
  });

  group('under-18 messaging limit', () {
    const mentor = Person(
      id: 'm-1',
      name: 'David Okello',
      role: PersonRole.mentor,
    );
    const minorPeer = Person(
      id: 's-9',
      name: 'Young Student',
      role: PersonRole.member,
      isAdult: false,
    );

    test('a restricted user cannot start or reply to adults', () async {
      final repo = FakeMessagingRepository(
        latency: Duration.zero,
        isRestricted: () => true,
      );
      expect(repo.canMessage(mentor), isFalse);
      expect(repo.canMessage(minorPeer), isTrue);
      expect(
        () => repo.openOrCreateThread(mentor, 'Mentor'),
        throwsA(isA<MessagingRestricted>()),
      );
      // Existing thread with a mentor: replies are refused too.
      expect(
        () => repo.sendMessage('thread-m-1', 'hi'),
        throwsA(isA<MessagingRestricted>()),
      );
      await repo.openOrCreateThread(minorPeer, 'Member');
    });

    test(
      'sign-up of a minor -> restricted until the guardian confirms',
      () async {
        final auth = FakeAuthRepository(latency: Duration.zero);
        final c = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWith((ref) => auth),
            profileRepositoryProvider.overrideWith(
              (ref) => FakeProfileRepository(latency: Duration.zero),
            ),
          ],
        );
        addTearDown(c.dispose);
        final now = DateTime.now();
        final minor = testProfile.copyWith(
          id: '',
          email: 'teen@fcu.test',
          username: 'teenstudent',
          birthdate: DateTime(now.year - 15, now.month, now.day),
        );
        final signUp = c.read(signUpControllerProvider.notifier)
          ..setDetails(minor)
          ..setPassword('letters1234');
        await auth.sendVerificationCode(minor.email);
        await auth.verifyCode(minor.email, FakeAuthRepository.fakeCode);
        signUp.markVerified();
        final profile = await signUp.complete(_consent());
        expect(isMinor(profile), isTrue);
        expect(c.read(signUpControllerProvider).hasDetails, isFalse);

        await c.read(guardianRequestProvider.future);
        expect(c.read(messagingRestrictedProvider), isTrue);
        final messaging = c.read(threadRepositoryProvider);
        expect(
          messaging.canMessage(
            const Person(
              id: 'sm-1',
              name: 'Grace',
              role: PersonRole.superMentor,
            ),
          ),
          isFalse,
        );

        final session = c.read(authSessionProvider)!;
        await auth.submitGuardianRequest(
          session.accountId,
          const GuardianRequest(
            guardianName: 'Ruth',
            guardianEmail: 'ruth@example.com',
            relationship: 'Parent',
          ),
          ownEmail: minor.email,
        );
        await auth.debugConfirmGuardian(session.accountId);
        c.invalidate(guardianRequestProvider);
        await c.read(guardianRequestProvider.future);
        expect(c.read(messagingRestrictedProvider), isFalse);
      },
    );
  });

  group('guard order (signed out / onboarding)', () {
    GuardContext ctx(
      String path, {
      AuthSession? session,
      UserProfile? profile,
      SignUpDraft draft = SignUpDraft.empty,
    }) => GuardContext(
      location: Uri.parse(path),
      profile: AsyncValue.data(profile),
      membership: const AsyncValue.data(Membership.empty),
      session: AsyncValue.data(session),
      signUp: draft,
    );

    const session = AuthSession(accountId: 'test-user', email: 'g@x.com');

    test('signed out: protected -> landing; sign-up/sign-in stay open', () {
      expect(runGuards(ctx('/communities')), '/');
      expect(runGuards(ctx('/login')), isNull);
      expect(runGuards(ctx('/forgot-password')), isNull);
      expect(runGuards(ctx('/charter')), isNull);
      expect(runGuards(ctx('/join')), isNull);
    });

    test('sign-up steps cannot be skipped', () {
      expect(runGuards(ctx('/join/password')), '/join');
      final details = SignUpDraft(details: testProfile);
      expect(runGuards(ctx('/join/password', draft: details)), isNull);
      expect(runGuards(ctx('/join/verify', draft: details)), '/join/password');
      final withPassword = details.copyWith(passwordDigest: 'x');
      expect(runGuards(ctx('/join/verify', draft: withPassword)), isNull);
      expect(
        runGuards(ctx('/join/consent', draft: withPassword)),
        '/join/verify',
      );
      expect(
        runGuards(
          ctx(
            '/join/consent',
            draft: withPassword.copyWith(emailVerified: true),
          ),
        ),
        isNull,
      );
      expect(runGuards(ctx('/join/guardian')), '/');
    });

    test('signed in without a profile finishes onboarding first', () {
      expect(runGuards(ctx('/communities', session: session)), '/join');
      expect(runGuards(ctx('/join', session: session)), isNull);
    });

    test('a complete account skips sign-up and sign-in pages', () {
      for (final path in [
        '/login',
        '/join',
        '/join/password',
        '/forgot-password',
      ]) {
        expect(
          runGuards(ctx(path, session: session, profile: testProfile)),
          '/communities',
          reason: path,
        );
      }
      expect(
        runGuards(
          ctx('/join/guardian', session: session, profile: testProfile),
        ),
        isNull,
      );
    });

    test('signed-out runs before onboarding', () {
      final i = defaultGuardChain.indexWhere((g) => g is SignedOutGuard);
      final j = defaultGuardChain.indexWhere(
        (g) => g is OnboardingIncompleteGuard,
      );
      expect(i, lessThan(j));
    });
  });
}
