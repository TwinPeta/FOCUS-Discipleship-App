import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/auth/presentation/sign_in_screen.dart';

import '../support/fake_backend.dart';
import '../support/fakes/auth_repository.dart';
import '../support/pump_utils.dart';

/// Records what was typed and answers like the API does after too many tries.
class _LimitedAuth extends FakeAuthRepository {
  final tried = <String>[];

  @override
  Future<AuthSession> signIn(String email, String password) async {
    tried.add(email);
    throw const ApiException(429);
  }
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (c, s) => const SignInScreen()),
            GoRoute(
              path: '/forgot-password',
              builder: (c, s) => const Scaffold(body: Text('FORGOT')),
            ),
          ],
        ),
      ),
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets('a username works, not only an email, and a limit is explained', (
    tester,
  ) async {
    final limited = _LimitedAuth();
    final container = fakeContainer(
      overrides: [authRepositoryProvider.overrideWithValue(limited)],
    );
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Email, phone or username'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '@grace');
    await tester.enterText(find.byType(TextField).at(1), 'SomePass123');
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await settle(tester);

    expect(limited.tried, ['@grace']);
    expect(find.text(SignInScreen.tooManyAttempts), findsOneWidget);
  });

  testWidgets('wrong details show the one generic message', (tester) async {
    final container = fakeContainer();
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.enterText(find.byType(TextField).at(0), 'nobody');
    await tester.enterText(find.byType(TextField).at(1), 'WrongPass123');
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await settle(tester);

    expect(find.text(SignInScreen.genericError), findsOneWidget);
  });
}
