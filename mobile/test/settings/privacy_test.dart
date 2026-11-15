import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';
import 'package:focus_1/features/auth/presentation/sign_in_screen.dart';
import 'package:focus_1/features/settings/data/privacy_repository.dart';
import 'package:focus_1/features/settings/presentation/privacy_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

/// The harness seeds testProfile's account with this password.
const _password = 'Password1234';

OutlinedButton _deleteButton(WidgetTester tester) =>
    tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(OutlinedButton, 'Delete my account'),
      ),
    );

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Delete my account'));
  await settle(tester);
  expect(find.text('Delete your account?'), findsOneWidget);
}

void main() {
  group('deleteAccount (repository)', () {
    test('wrong password deletes nothing; right password ends it', () async {
      final auth = FakeAuthRepository(latency: Duration.zero)
        ..debugSeedAccount('a@fcu.test', _password, 'a')
        ..debugSignInAs('a@fcu.test');
      await expectLater(
        auth.deleteAccount('nope'),
        throwsA(isA<InvalidCredentials>()),
      );
      expect(await auth.currentSession(), isNotNull);

      await auth.deleteAccount(_password);
      expect(await auth.currentSession(), isNull);
      await expectLater(
        auth.signIn('a@fcu.test', _password),
        throwsA(isA<InvalidCredentials>()),
        reason: 'the account no longer exists',
      );
      expect(await auth.isEmailAvailable('a@fcu.test'), isTrue);
    });

    test('signed out: deleting is refused', () async {
      final auth = FakeAuthRepository(latency: Duration.zero);
      await expectLater(
        auth.deleteAccount(_password),
        throwsA(isA<InvalidCredentials>()),
      );
    });
  });

  testWidgets('48: download my data, rows and retention note', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/settings/privacy');

    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text('You control your information.'), findsOneWidget);
    expect(
      find.textContaining('kept for $dataRetentionMonths months'),
      findsOneWidget,
    );

    await tester.tap(find.text('Download my data'));
    await settle(tester);
    expect(find.textContaining('We will email you a copy'), findsOneWidget);
    final privacy =
        container.read(privacyRepositoryProvider) as FakePrivacyRepository;
    expect(privacy.exportRequests, {testProfile.id});
  });

  testWidgets('49: disabled until a password; wrong one shows an error', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/settings/privacy');
    await _openSheet(tester);

    expect(
      find.textContaining('deleted within $deletionWindowDays days'),
      findsOneWidget,
    );
    expect(_deleteButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'wrong-password');
    await tester.pump();
    expect(_deleteButton(tester).onPressed, isNotNull);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(OutlinedButton, 'Delete my account'),
      ),
    );
    await settle(tester, steps: 12);
    expect(find.text('That password is not correct.'), findsOneWidget);
    expect(container.read(authSessionProvider), isNotNull);

    await tester.tap(find.text('Keep my account'));
    await settle(tester);
    expect(find.text('Delete your account?'), findsNothing);
    expect(find.byType(PrivacyScreen), findsOneWidget);
  });

  testWidgets('49: the right password deletes everything -> /login', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/settings/privacy');
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), _password);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(OutlinedButton, 'Delete my account'),
      ),
    );
    await settle(tester, steps: 20);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(container.read(authSessionProvider), isNull);
    late Object? profile;
    await tester.runAsync(
      () async => profile = await container
          .read(profileRepositoryProvider)
          .getProfile(testProfile.id),
    );
    expect(profile, isNull);
    final membership = await tester.runAsync(
      () => container.read(membershipRepositoryProvider).getMembership(),
    );
    expect(membership!.communityId, isNull);
  });
}
