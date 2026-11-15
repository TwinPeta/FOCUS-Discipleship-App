import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('the emoji button opens the phone keyboard, not a panel', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/community/growth-circle/compose');

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);

    await tester.tap(find.bySemanticsLabel('Emoji keyboard'));
    await tester.pump();

    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    // The old custom emoji grid is gone.
    expect(find.byType(GridView), findsNothing);
    expect(find.text('🙏'), findsNothing);

    // Emojis typed from the phone keyboard go into the post as-is.
    await tester.enterText(field, 'Praise 🙏❤️');
    await tester.pump();
    expect(find.text('Praise 🙏❤️'), findsOneWidget);
  });
}
