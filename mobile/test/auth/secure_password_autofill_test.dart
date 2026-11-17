import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';
import 'package:focus_1/features/auth/presentation/secure_password_screen.dart';

import '../support/fake_backend.dart';
import '../support/pump_utils.dart';

void main() {
  testWidgets('21: the new password is grouped with the account email, so '
      'the phone saves it under that login', (tester) async {
    final container = fakeContainer();
    addTearDown(container.dispose);
    container.read(signUpControllerProvider.notifier).setDetails(testProfile);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) => const SecurePasswordScreen(),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    final account = fields.firstWhere((f) => f.readOnly);
    expect(account.controller!.text, testProfile.email);
    expect(account.autofillHints, contains(AutofillHints.username));
    expect(
      fields.where(
        (f) => f.autofillHints?.contains(AutofillHints.newPassword) ?? false,
      ),
      isNotEmpty,
    );
    expect(find.textContaining('@${testProfile.username}'), findsOneWidget);
    // Same autofill group as the password fields.
    expect(
      find.ancestor(
        of: find.byWidget(account),
        matching: find.byType(AutofillGroup),
      ),
      findsOneWidget,
    );
  });
}
