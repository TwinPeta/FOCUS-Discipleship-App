import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/connectivity/connectivity_service.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

/// Screens 56/57/59 applied to the inbox and the conversation.
void main() {
  testWidgets('offline: the conversation keeps the field but disables send', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/messages/thread-sm-1');
    await settle(tester, steps: 10);

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).enabled, isTrue);

    (container.read(connectivityServiceProvider) as FakeConnectivityService)
        .setOnline(false);
    await settle(tester);

    expect(find.text('You are offline'), findsWidgets); // banner + hint
    expect(tester.widget<TextField>(field).enabled, isFalse);
    // Earlier messages stay readable.
    expect(find.textContaining('checking in'), findsOneWidget);
  });

  testWidgets('offline: the inbox shows the banner above the threads', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    (container.read(connectivityServiceProvider) as FakeConnectivityService)
        .setOnline(false);
    await goTo(tester, container, '/messages');
    await settle(tester, steps: 10);

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Grace Namuli'), findsOneWidget);
  });
}
