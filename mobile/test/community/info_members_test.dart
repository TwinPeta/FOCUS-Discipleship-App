import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/widgets/list_row_card.dart';
import 'package:focus_1/features/messaging/presentation/widgets/message_person_button.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

void main() {
  testWidgets('6: members, leaders first; tap opens the profile; message '
      'buttons for others', (tester) async {
    final app = await pumpFcuApp(tester, size: const Size(390, 1600));
    await goTo(tester, app, '/community/growth-circle/info');
    await settle(tester, steps: 14);

    expect(find.textContaining('Members · '), findsOneWidget);
    expect(find.textContaining('online'), findsWidgets);

    final rows = tester
        .widgetList<ListRowCard>(find.byType(ListRowCard))
        .toList();
    expect(rows, isNotEmpty);
    // The super-mentor comes first.
    expect(rows.first.subtitle, startsWith('Super-mentor'));
    // Every other member can be messaged.
    expect(
      find.byType(MessagePersonButton),
      findsNWidgets(rows.where((r) => !r.title.endsWith('(you)')).length),
    );

    await tester.tap(find.text(rows[1].title));
    await settle(tester, steps: 10);
    expect(app.read(routerProvider).state.uri.path, startsWith('/members/'));
    await tester.pump(const Duration(seconds: 2));
  });
}
