import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_1/core/diagnostics/crash_log.dart';
import 'package:focus_1/core/realtime/realtime_client.dart';

void main() {
  test('keeps the last 20 errors, newest last, with a short stack', () async {
    SharedPreferences.setMockInitialValues({});
    final log = CrashLog(await SharedPreferences.getInstance());
    for (var i = 1; i <= 25; i++) {
      log.record(StateError('boom $i'), StackTrace.current, source: 'async');
    }
    final entries = log.entries;
    expect(entries, hasLength(CrashLog.maxEntries));
    expect(entries.first.error, contains('boom 6'));
    expect(entries.last.error, contains('boom 25'));
    expect(entries.last.stack.split('\n').length, lessThanOrEqualTo(12));
    log.clear();
    expect(log.entries, isEmpty);
  });

  test('without storage it records nothing and never throws', () {
    final log = CrashLog(null)
      ..record(Exception('x'), null, source: 'flutter');
    expect(log.entries, isEmpty);
  });

  for (final size in [const Size(40, 20), const Size(360, 120)]) {
    testWidgets('the broken-part card fits $size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.fromSize(size: size, child: const BrokenPart()),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  }

  test('the realtime token goes as a subprotocol marker', () {
    expect(WebSocketRealtimeChannel.bearerProtocol, 'fcu.bearer');
  });
}
