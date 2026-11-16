import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/widgets/community_header_chrome.dart';
import 'package:focus_1/features/prayer/presentation/prayer_wall_screen.dart';
import 'package:focus_1/features/prayer/presentation/providers/prayer_providers.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

void main() {
  testWidgets('14: the header shows the section; "⋯" lists every section '
      'with the current one marked, and switches', (tester) async {
    final semantics = tester.ensureSemantics();
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/community/growth-circle/prayer');
    String path() => app.read(routerProvider).state.uri.path;
    Finder inHeader(String text) => find.descendant(
      of: find.byType(CommunityHeaderChrome),
      matching: find.text(text),
    );

    // No online count, no messages button; Search and the menu instead.
    expect(find.textContaining('online'), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsNothing);
    expect(inHeader('Prayer wall'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await settle(tester);
    for (final s in [
      'General',
      'Feed',
      'Testimonies',
      'Pathways',
      'Resources',
      'Info & members',
      'Meetings',
    ]) {
      expect(find.bySemanticsLabel(s), findsOneWidget, reason: s);
    }
    expect(find.bySemanticsLabel('Prayer wall, current'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Testimonies'));
    await settle(tester);
    expect(path(), '/community/growth-circle/testimonies');
    expect(inHeader('Testimonies'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('General'));
    await settle(tester);
    expect(path(), '/general-feed');
    semantics.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('14: "I prayed" and its count are one button', (tester) async {
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/community/growth-circle/prayer');
    await settle(tester);
    final first = tester.widget<PrayedButton>(find.byType(PrayedButton).first);
    await tester.tap(find.byType(PrayedButton).first);
    await settle(tester);
    // Read back from the data: the first "I prayed" may also open a badge
    // celebration over the wall.
    final after = app
        .read(prayerRequestsProvider('growth-circle'))
        .value!
        .first;
    expect(after.prayedByMe, !first.prayed);
    expect(after.prayedCount, first.count + (first.prayed ? -1 : 1));
    await tester.pump(const Duration(seconds: 2));
  });
}
