import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';
import 'package:focus_1/features/auth/presentation/verify_email_screen.dart';

import '../support/fake_backend.dart';
import '../support/pump_utils.dart';

void main() {
  test('the countdown reads as minutes and seconds', () {
    expect(ResendCodeRow.clock(30), '0:30');
    expect(ResendCodeRow.clock(65), '1:05');
    expect(ResendCodeRow.clock(600), '10:00');
    expect(ResendCodeRow.clock(-3), '0:00');
  });

  testWidgets('22: "Send a new code" waits for the countdown', (tester) async {
    final container = fakeContainer();
    addTearDown(container.dispose);
    container.read(signUpControllerProvider.notifier)
      ..setDetails(testProfile)
      ..setPassword('Password1234');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (c, s) => const VerifyEmailScreen()),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    // A code was sent on arrival: the countdown runs, no resend button yet.
    expect(find.textContaining('New code in 0:'), findsOneWidget);
    expect(find.text('Send a new code'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.text('Send a new code'), findsOneWidget);
    expect(find.textContaining('New code in'), findsNothing);

    // Sending again restarts the countdown.
    await tester.tap(find.text('Send a new code'));
    await settle(tester);
    expect(find.textContaining('New code in 0:'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
  });
}
