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
  testWidgets('Home, Caregroups, Messages, Profile tabs (approved member)', (
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

    // Communities opens the hub for everyone, as in the design.
    await _tapTab(tester, Icons.groups_outlined);
    expect(path(), '/communities');
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

  testWidgets('Caregroups goes to the hub without a caregroup', (
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

  testWidgets('Create opens the menu; every type opens the Create screen', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/general-feed');
    Uri uri() => container.read(routerProvider).state.uri;

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
      expect(_row(tester, t).onTap, isNotNull, reason: t);
    }

    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.byType(CreateMenuSheet), findsNothing);

    for (final (row, type) in [
      ('Write a post', 'post'),
      ('Ask a question', 'question'),
      ('Prayer request', 'prayer'),
      ('Share a story', 'story'),
    ]) {
      await goTo(tester, container, '/general-feed');
      await _openCreate(tester);
      await tester.tap(find.text(row));
      await settle(tester, steps: 12);
      expect(uri().path, '/create', reason: row);
      expect(uri().queryParameters['type'], type, reason: row);
    }

    await goTo(tester, container, '/general-feed');
    await _openCreate(tester);
    await tester.tap(find.text('Answer a question'));
    await settle(tester, steps: 12);
    expect(uri().path, '/questions');
  });

  testWidgets('old "new" links open the Create screen', (tester) async {
    final container = await pumpFcuApp(tester);
    Uri uri() => container.read(routerProvider).state.uri;
    for (final (old, type, to) in [
      ('/community/growth-circle/compose', 'post', 'growth-circle'),
      ('/community/growth-circle/prayer/new', 'prayer', 'growth-circle'),
      ('/community/growth-circle/testimonies/new', 'story', 'growth-circle'),
      ('/general-feed/compose', 'post', 'general'),
    ]) {
      await goTo(tester, container, old);
      expect(uri().path, '/create', reason: old);
      expect(uri().queryParameters['type'], type, reason: old);
      expect(uri().queryParameters['to'], to, reason: old);
    }
  });
}
