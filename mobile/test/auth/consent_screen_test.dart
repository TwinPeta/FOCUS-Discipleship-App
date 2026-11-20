import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/auth/presentation/consent_screen.dart';
import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';

import '../support/pump_utils.dart';
import '../support/fake_backend.dart';

void main() {
  testWidgets(
    'Join my campus needs all three required boxes, all start unticked',
    (tester) async {
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
                GoRoute(path: '/', builder: (c, s) => const ConsentScreen()),
              ],
            ),
          ),
        ),
      );
      await settle(tester);

      ElevatedButton join() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Join my campus'),
      );
      final checked = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.checked == true);
      expect(checked, isEmpty, reason: 'nothing may be pre-ticked');
      expect(join().onPressed, isNull);

      await tester.ensureVisible(
        find.textContaining('I accept the caregroup charter'),
      );
      await tester.tap(find.textContaining('I accept the caregroup charter'));
      await tester.pump();
      expect(join().onPressed, isNull);

      await tester.ensureVisible(
        find.textContaining('I agree that a mentor may contact me'),
      );
      await tester.tap(
        find.textContaining('I agree that a mentor may contact me'),
      );
      await tester.pump();
      expect(
        join().onPressed,
        isNull,
        reason: 'the optional box is not enough',
      );

      await tester.ensureVisible(find.textContaining('caregroup spaces'));
      await tester.tap(find.textContaining('caregroup spaces'));
      await tester.pump();
      expect(
        join().onPressed,
        isNull,
        reason: 'national activities is required',
      );

      await tester.ensureVisible(
        find.textContaining('FOCUS national activities'),
      );
      await tester.tap(find.textContaining('FOCUS national activities'));
      await tester.pump();
      expect(join().onPressed, isNotNull);
    },
  );
}
