import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/learning/presentation/badge_earned_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

void main() {
  testWidgets('Mark as read on a devotional opens Badge earned, then Continue '
      'returns to the viewer', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/community/growth-circle/resources');
    await goTo(tester, container, '/devotional/resource-2');

    final markRead = find.text('Mark as read');
    await tester.ensureVisible(markRead);
    await tester.tap(markRead);
    await settle(tester);

    // First activity ever: the "First steps" badge celebrates on screen 38.
    expect(find.byType(BadgeEarnedScreen), findsOneWidget);
    expect(find.text('First steps'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.byType(BadgeEarnedScreen), findsNothing);
    expect(find.text('Your reflection'), findsOneWidget);
  });
}
