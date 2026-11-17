import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/app_router.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

/// The phone's Back button never closes the app from inside it: it does
/// what the screen's own Back does, and only Home lets the app close.
void main() {
  late List<MethodCall> systemCalls;

  setUp(() {
    systemCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          systemCalls.add(call);
          return null;
        });
  });

  bool appClosed() => systemCalls.any((c) => c.method == 'SystemNavigator.pop');

  Future<void> phoneBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester, steps: 10);
  }

  testWidgets('screens reached with go: Back goes to their parent', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    String where() => app.read(routerProvider).state.uri.path;

    for (final (from, to) in [
      ('/general-feed/prayer', '/general-feed'), // General section via "⋯"
      ('/messages', '/communities'), // its own Back arrow
      ('/communities', '/general-feed'), // a main tab
      ('/profile', '/general-feed'),
      ('/messages/thread-sm-1', '/messages'), // deep link, own fallback
      ('/community/growth-circle/prayer', '/communities'),
    ]) {
      await goTo(tester, app, from);
      await settle(tester, steps: 10);
      await phoneBack(tester);
      expect(where(), to, reason: 'Back from $from');
      expect(appClosed(), isFalse, reason: 'Back from $from closed the app');
    }
  });

  testWidgets('a pushed screen pops back to where it came from', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    String where() => app.read(routerProvider).state.uri.path;
    await goTo(tester, app, '/messages/thread-sm-1');
    unawaited(app.read(routerProvider).push('/members/sm-1'));
    await settle(tester, steps: 10);
    await phoneBack(tester);
    expect(where(), '/messages/thread-sm-1');
  });

  testWidgets('an open menu closes first; Home lets the app close', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    String where() => app.read(routerProvider).state.uri.path;
    await goTo(tester, app, '/general-feed');
    await settle(tester, steps: 10);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await settle(tester);
    expect(find.text('General prayer wall'), findsOneWidget);
    await phoneBack(tester);
    expect(find.text('General prayer wall'), findsNothing);
    expect(where(), '/general-feed');
    expect(appClosed(), isFalse);

    await phoneBack(tester);
    expect(appClosed(), isTrue);
  });
}
