import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

void main() {
  testWidgets('9: "⋯" filters the inbox; the header names the filter', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/messages');
    await settle(tester, steps: 10);

    expect(find.text('All conversations'), findsOneWidget);
    expect(find.text('Grace Namuli'), findsOneWidget);
    expect(find.text('David Okello'), findsOneWidget);

    Future<void> pick(String label) async {
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await settle(tester);
      await tester.tap(find.text(label).last);
      await settle(tester);
    }

    // Unread: only the conversation with unread messages.
    await pick('Unread');
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Grace Namuli'), findsOneWidget);
    expect(find.text('David Okello'), findsNothing);

    // Members: neither leader.
    await pick('Members');
    expect(find.text('Grace Namuli'), findsNothing);

    await pick('All conversations');
    expect(find.text('David Okello'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
