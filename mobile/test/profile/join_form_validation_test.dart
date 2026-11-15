import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/profile/presentation/join_form_screen.dart';

import '../support/pump_utils.dart';
import '../support/fake_backend.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: fakeBackend(),
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: GoRouter(
        initialLocation: '/x',
        routes: [
          GoRoute(
            path: '/x',
            builder: (context, state) => const JoinFormScreen(),
          ),
          GoRoute(
            path: '/join/password',
            builder: (context, state) =>
                const Scaffold(body: Text('PASSWORD STEP')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('shows required-field errors when submitting empty', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await settle(tester);

    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Birthdate is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);
    // Still on the Join form, not navigated away.
    expect(find.text('PASSWORD STEP'), findsNothing);
  });

  testWidgets('rejects an invalid username and email', (tester) async {
    await tester.pumpWidget(_wrap());
    await settle(tester);

    await tester.enterText(find.widgetWithText(TextField, 'username'), 'ab');
    await tester.enterText(
      find.widgetWithText(TextField, 'you@example.com'),
      'not-an-email',
    );
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(
      find.text('3-20 characters: letters, numbers and underscores only'),
      findsOneWidget,
    );
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('valid details continue to the password step', (tester) async {
    await tester.pumpWidget(_wrap());
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Grace Namuli'),
      'Grace Namuli',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'username'),
      'gracenamuli',
    );

    // Birthdate via the date picker, before scrolling moves it off-screen.
    final birthdateField = find.widgetWithText(TextField, 'DD / MM / YYYY');
    await tester.ensureVisible(birthdateField);
    await settle(tester);
    await tester.tap(birthdateField);
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'you@example.com'),
      'grace@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '+256 700 000 000'),
      '+256700000000',
    );

    // Pick a university from the seeded list for the default country (Uganda).
    final universityDropdown = find.text('Select your university');
    await tester.ensureVisible(universityDropdown);
    await settle(tester);
    await tester.tap(universityDropdown);
    await settle(tester);
    await tester.tap(find.text('Makerere University').last);
    await settle(tester);

    await tester.tap(find.text('Continue'));
    await settle(tester);

    // Sign-up continues to the password step; nothing is created yet.
    expect(find.text('PASSWORD STEP'), findsOneWidget);
  });
}
