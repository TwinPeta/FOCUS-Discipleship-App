import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/permissions/app_permissions.dart';
import 'package:focus_1/core/permissions/permission_prompt.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/theme/app_theme.dart';

import '../support/fake_backend.dart';
import '../support/fakes.dart';

void main() {
  /// Pumps a button that runs ensurePermission for the camera and records
  /// the result.
  Future<List<bool>> pump(
    WidgetTester tester,
    FakePermissionService service,
  ) async {
    final results = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeBackend(),
          permissionServiceProvider.overrideWith((ref) => service),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async => results.add(
                  await ensurePermission(
                    context,
                    ref,
                    AppPermission.camera,
                    PermissionReasons.cameraPhoto,
                  ),
                ),
                child: const Text('Take photo'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('already granted: no sheet, returns true', (tester) async {
    final service = FakePermissionService();
    final results = await pump(tester, service);
    expect(find.text('Allow camera'), findsNothing);
    expect(results, [true]);
    expect(service.requested, isEmpty);
  });

  testWidgets('denied: reason sheet, Continue requests and grants', (
    tester,
  ) async {
    final service = FakePermissionService(initial: AppPermissionStatus.denied);
    final results = await pump(tester, service);
    expect(find.text('Allow camera'), findsOneWidget);
    expect(find.text(PermissionReasons.cameraPhoto), findsOneWidget);
    expect(service.requested, isEmpty);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(service.requested, [AppPermission.camera]);
    expect(results, [true]);
    expect(find.text('Allow camera'), findsNothing);
  });

  testWidgets('denied: Not now returns false without asking', (tester) async {
    final service = FakePermissionService(initial: AppPermissionStatus.denied);
    final results = await pump(tester, service);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(service.requested, isEmpty);
    expect(results, [false]);
  });

  testWidgets('permanently denied: explains and opens settings', (
    tester,
  ) async {
    final service = FakePermissionService(
      initial: AppPermissionStatus.denied,
      onRequest: AppPermissionStatus.permanentlyDenied,
    );
    final results = await pump(tester, service);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Camera access is off'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(service.settingsOpened, 1);
    expect(results, [false]);
  });

  testWidgets('sheet buttons are at least 44px tall', (tester) async {
    await pump(
      tester,
      FakePermissionService(initial: AppPermissionStatus.denied),
    );
    for (final label in ['Continue', 'Not now']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(tester.getSize(button.first).height, greaterThanOrEqualTo(44));
    }
  });
}
