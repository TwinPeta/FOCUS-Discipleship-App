import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/widgets/otp_field.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/pump_utils.dart';

/// Step 2's fields, in order: the code, the new password, the repeat.
Future<void> _type(WidgetTester tester, int index, String text) async {
  await tester.enterText(find.byType(TextField).at(index), text);
  await tester.pump();
}

void main() {
  testWidgets('26: email, then the code and a new password, then sign in', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester, signedIn: false);
    await goTo(tester, app, '/forgot-password');

    expect(find.text('Forgot password?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, testProfile.email);
    await tester.pump();
    await tester.tap(find.text('Send code'));
    await settle(tester);

    expect(find.text('Set a new password'), findsOneWidget);
    expect(find.textContaining('6-digit code'), findsWidgets);
    expect(find.textContaining('New code in'), findsOneWidget);

    // A wrong code is refused.
    await tester.enterText(
      find.descendant(
        of: find.byType(OtpField),
        matching: find.byType(TextField),
      ),
      '000000',
    );
    await _type(tester, 1, 'Fresh-pass-2026');
    await _type(tester, 2, 'Fresh-pass-2026');
    await tester.ensureVisible(find.text('Set new password'));
    await tester.tap(find.text('Set new password'));
    await settle(tester);
    expect(find.textContaining('That code is not right'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(OtpField),
        matching: find.byType(TextField),
      ),
      FakeAuthRepository.fakeCode,
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Set new password'));
    await tester.tap(find.text('Set new password'));
    await settle(tester);
    expect(app.read(routerProvider).state.uri.path, '/login');

    // The fake sign-in waits on real timers: run it outside fake time.
    final auth = app.read(authRepositoryProvider);
    await tester.runAsync(() async {
      await expectLater(
        auth.signIn(testProfile.email, 'Password1234'),
        throwsA(isA<InvalidCredentials>()),
      );
      expect(
        (await auth.signIn(testProfile.email, 'Fresh-pass-2026')).email,
        testProfile.email,
      );
    });
    await tester.pump(const Duration(seconds: 31));
  });
}
