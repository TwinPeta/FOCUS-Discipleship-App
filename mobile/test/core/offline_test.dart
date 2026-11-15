import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/connectivity/connectivity_service.dart';
import 'package:focus_1/core/connectivity/offline_cache.dart';
import 'package:focus_1/core/widgets/pill_button.dart';
import 'package:focus_1/core/widgets/tab_section_header.dart';
import 'package:focus_1/features/feed/presentation/widgets/compose_fab.dart';

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

  testWidgets('offline feed: banner tip, saved marker, posting disabled', (
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
    expect(find.text('Posting is paused offline'), findsOneWidget);
    expect(
      find.bySemanticsLabel('New post. Posting is paused while offline'),
      findsOneWidget,
    );
    expect(find.byType(ComposeFab), findsOneWidget);

    net.setOnline(true);
    await settle(tester);
    expect(find.text('You are offline'), findsNothing);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('offline prayer wall: "I prayed" disabled, not hidden', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/community/growth-circle/prayer');
    final net =
        container.read(connectivityServiceProvider) as FakeConnectivityService;
    net.setOnline(false);
    await settle(tester);

    final pills = tester
        .widgetList<PillButton>(find.byType(PillButton))
        .where((p) => p.label.contains('prayed'));
    expect(pills, isNotEmpty);
    expect(pills.every((p) => p.onTap == null), isTrue);
    expect(find.text('Saved'), findsOneWidget);
    final header = tester.widget<TabSectionHeader>(
      find.byType(TabSectionHeader),
    );
    expect(header.onAction, isNull);
    expect(header.actionLabel, 'Share a request. Paused while offline');
  });
}
