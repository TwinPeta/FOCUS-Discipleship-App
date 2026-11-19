import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/core/widgets/otp_field.dart';
import 'package:focus_1/features/auth/presentation/forgot_password_screen.dart';

import '../support/fake_backend.dart';

import '../support/fakes/auth_repository.dart';

import '../support/pump_utils.dart';

void main() {
  testWidgets('the emailed code and a new password reset it and sign in', (
    tester,
  ) async {
    final container = fakeContainer();
    addTearDown(container.dispose);
    final repo = container.read(authRepositoryProvider) as FakeAuthRepository;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) => const ForgotPasswordScreen(),
              ),
              GoRoute(
                path: '/communities',
                builder: (c, s) => const Scaffold(body: Text('SIGNED IN')),
              ),
              GoRoute(
                path: '/login',
                builder: (c, s) => const Scaffold(body: Text('LOGIN')),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    // Step 1: ask for a code.
    await tester.enterText(
      find.byType(TextField).first,
      FakeAuthRepository.demoEmail,
    );
    await tester.pump();
    await tester.tap(find.text('Send code'));
    await settle(tester);
    expect(repo.resetRequests, [FakeAuthRepository.demoEmail]);
    expect(find.text('Set a new password'), findsOneWidget);

    Future<void> fill(String code) async {
      final otp = find.descendant(
        of: find.byType(OtpField),
        matching: find.byType(TextField),
      );
      await tester.enterText(otp, code);
      await tester.pump();
    }

    const fresh = 'BrandNewPass99';
    final passwords = find.byType(EditableText);
    await fill('000000');
    // The two password fields come after the code field.
    await tester.enterText(passwords.at(1), fresh);
    await tester.enterText(passwords.at(2), fresh);
    await tester.pump();

    // A wrong code is refused and nothing changes.
    await tester.ensureVisible(find.text('Set new password'));
    await tester.tap(find.text('Set new password'));
    await settle(tester);
    expect(find.text(ForgotPasswordScreen.codeError), findsOneWidget);
    expect(find.text('SIGNED IN'), findsNothing);

    // The right code changes the password and signs in.
    await fill(FakeAuthRepository.resetCode);
    await tester.ensureVisible(find.text('Set new password'));
    await tester.tap(find.text('Set new password'));
    await settle(tester);
    expect(find.text('SIGNED IN'), findsOneWidget);
  });
}
