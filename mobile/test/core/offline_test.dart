import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/connectivity/connectivity_service.dart';
import 'package:focus_1/core/connectivity/offline_cache.dart';
import 'package:focus_1/core/widgets/tab_section_header.dart';
import 'package:focus_1/features/prayer/presentation/prayer_wall_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';
import '../support/fake_backend.dart';

final _probe = FutureProvider.family<int, String>((ref, key) {
  final calls = ref.read(_calls);
  return loadWithOfflineCache(ref, key, () async => ++calls.value);
});
final _calls = Provider((ref) => _Counter());

class _Counter {
  int value = 0;
}

void main() {
  group('loadWithOfflineCache', () {
    test('online loads and saves; offline serves the saved copy', () async {
      final net = FakeConnectivityService();
      final c = fakeContainer(
        overrides: [connectivityServiceProvider.overrideWithValue(net)],
      );
      addTearDown(c.dispose);

      expect(await c.read(_probe('feed').future), 1);
      net.setOnline(false);
      c.invalidate(_probe('feed'));
      expect(await c.read(_probe('feed').future), 1, reason: 'cached copy');
      net.setOnline(true);
      c.invalidate(_probe('feed'));
      expect(await c.read(_probe('feed').future), 2, reason: 'fresh load');
    });

    test('offline with nothing saved still tries to load', () async {
      final net = FakeConnectivityService(online: false);
      final c = fakeContainer(
        overrides: [connectivityServiceProvider.overrideWithValue(net)],
      );
      addTearDown(c.dispose);
      expect(await c.read(_probe('prayer').future), 1);
    });
  });

  testWidgets('offline feed: banner tip, saved marker, posting still works', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/community/growth-circle/feed');
    final net =
        container.read(connectivityServiceProvider) as FakeConnectivityService;
    net.setOnline(false);
    await settle(tester);

    expect(find.text('You are offline'), findsOneWidget);
    expect(
      find.text(
        'Tip: turn on Data saver to use less data on slow connections.',
      ),
      findsOneWidget,
    );
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Share something (sent later)…'), findsOneWidget);
    // The composer's shortcuts stay usable: writes are sent later.
    for (final tip in ['Ask a question', 'Prayer request']) {
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(
          IconButton,
          tip == 'Ask a question'
              ? Icons.help_outline_rounded
              : Icons.volunteer_activism_outlined,
        ),
      );
      expect(button.onPressed, isNotNull, reason: tip);
    }

    net.setOnline(true);
    await settle(tester);
    expect(find.text('You are offline'), findsNothing);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('offline prayer wall: "I prayed" and sharing still work', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/community/growth-circle/prayer');
    final net =
        container.read(connectivityServiceProvider) as FakeConnectivityService;
    net.setOnline(false);
    await settle(tester);

    final pills = tester.widgetList<PrayedButton>(find.byType(PrayedButton));
    expect(pills, isNotEmpty);
    expect(pills.every((p) => p.onTap != null), isTrue);
    expect(find.text('Saved'), findsOneWidget);
    final header = tester.widget<TabSectionHeader>(
      find.byType(TabSectionHeader),
    );
    expect(header.onAction, isNotNull);
    expect(header.actionLabel, 'Share a request. Sent when back online');
  });
}
