import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/widgets/app_bottom_nav.dart';
import 'package:focus_1/features/community/domain/membership.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

Future<void> _tapTab(WidgetTester tester, IconData icon) async {
  await tester.tap(
    find.descendant(of: find.byType(AppBottomNav), matching: find.byIcon(icon)),
  );
  await settle(tester, steps: 12);
}

void main() {
  testWidgets('Home, Community, Profile tabs (approved member)', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    String path() => container.read(routerProvider).state.uri.path;

    await goTo(tester, container, '/general-feed');
    expect(find.byType(AppBottomNav), findsOneWidget);

    await _tapTab(tester, Icons.groups_outlined);
    expect(path(), '/community/growth-circle/feed');
    expect(find.byType(AppBottomNav), findsOneWidget);

    await _tapTab(tester, Icons.person_outline_rounded);
    expect(path(), '/profile');

    await _tapTab(tester, Icons.home_outlined);
    expect(path(), '/general-feed');
    // Tabs use `go`: no back stack builds up.
    expect(container.read(routerProvider).canPop(), isFalse);
  });

  testWidgets('Community goes to the hub without a community', (tester) async {
    final container = await pumpFcuApp(
      tester,
      membership: MembershipStatus.none,
    );
    await goTo(tester, container, '/profile');
    await _tapTab(tester, Icons.groups_outlined);
    expect(container.read(routerProvider).state.uri.path, '/communities');
    expect(find.byType(AppBottomNav), findsOneWidget);
  });
}
