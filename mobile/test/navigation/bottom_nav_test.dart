import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/widgets/app_bottom_nav.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/create/presentation/create_menu_sheet.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

Future<void> _tapTab(WidgetTester tester, IconData icon) async {
  await tester.tap(
    find.descendant(of: find.byType(AppBottomNav), matching: find.byIcon(icon)),
  );
  await settle(tester, steps: 12);
}

Future<void> _openCreate(WidgetTester tester) =>
    _tapTab(tester, Icons.add_rounded);

CreateMenuRow _row(WidgetTester tester, String title) =>
    tester.widget<CreateMenuRow>(find.widgetWithText(CreateMenuRow, title));

void main() {
  testWidgets('Home, Communities, Messages, Profile tabs (approved member)', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    String path() => container.read(routerProvider).state.uri.path;
    Finder navText(String t) =>
        find.descendant(of: find.byType(AppBottomNav), matching: find.text(t));

    await goTo(tester, container, '/general-feed');
    expect(find.byType(AppBottomNav), findsOneWidget);
    // Label on the selected tab only.
    expect(navText('Home'), findsOneWidget);
    expect(navText('Messages'), findsNothing);

    await _tapTab(tester, Icons.groups_outlined);
    expect(path(), '/community/growth-circle/feed');
    expect(find.byType(AppBottomNav), findsOneWidget);

    await _tapTab(tester, Icons.chat_bubble_outline_rounded);
    expect(path(), '/messages');
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(navText('Messages'), findsOneWidget);

    await _tapTab(tester, Icons.person_outline_rounded);
    expect(path(), '/profile');

    await _tapTab(tester, Icons.home_outlined);
    expect(path(), '/general-feed');
    // Tabs use `go`: no back stack builds up.
    expect(container.read(routerProvider).canPop(), isFalse);
  });

  testWidgets('Communities goes to the hub without a community', (
    tester,
  ) async {
    final container = await pumpFcuApp(
      tester,
      membership: MembershipStatus.none,
    );
    await goTo(tester, container, '/profile');
    await _tapTab(tester, Icons.groups_outlined);
    expect(container.read(routerProvider).state.uri.path, '/communities');
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('Create opens the menu; Cancel closes; Write a post opens the '
      'community composer', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/general-feed');

    await _openCreate(tester);
    expect(find.byType(CreateMenuSheet), findsOneWidget);
    for (final t in [
      'Ask a question',
      'Answer a question',
      'Write a post',
      'Prayer request',
      'Share a story',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Coming soon'), findsNWidgets(2));
    expect(_row(tester, 'Ask a question').onTap, isNull);
    expect(_row(tester, 'Answer a question').onTap, isNull);
    expect(_row(tester, 'Prayer request').onTap, isNotNull);
    expect(_row(tester, 'Share a story').onTap, isNotNull);

    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.byType(CreateMenuSheet), findsNothing);

    await _openCreate(tester);
    await tester.tap(find.text('Write a post'));
    await settle(tester, steps: 12);
    expect(find.byType(CreateMenuSheet), findsNothing);
    expect(
      container.read(routerProvider).state.uri.path,
      '/community/growth-circle/compose',
    );
  });

  testWidgets(
    'Without a community: post goes to General; prayer and story disabled',
    (tester) async {
      final container = await pumpFcuApp(
        tester,
        membership: MembershipStatus.none,
      );
      await goTo(tester, container, '/profile');
      await _openCreate(tester);

      expect(_row(tester, 'Prayer request').onTap, isNull);
      expect(_row(tester, 'Share a story').onTap, isNull);
      expect(find.text('Join a community first'), findsNWidgets(2));

      await tester.tap(find.text('Write a post'));
      await settle(tester, steps: 12);
      expect(
        container.read(routerProvider).state.uri.path,
        '/general-feed/compose',
      );
    },
  );
}
