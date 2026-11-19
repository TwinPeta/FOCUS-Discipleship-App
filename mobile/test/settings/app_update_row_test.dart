import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/update/app_update.dart';
import 'package:focus_1/features/settings/presentation/app_update_row.dart';

Map<String, dynamic> _release(String version) => {
  'tag_name': 'mobile-v$version',
  'assets': [
    {
      'name': 'fcu.apk',
      'browser_download_url': 'https://example.test/$version/fcu.apk',
    },
  ],
};

Future<void> _pump(
  WidgetTester tester, {
  required String version,
  required Future<Map<String, dynamic>?> Function() fetch,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentVersionProvider.overrideWithValue(version),
        latestReleaseFetcherProvider.overrideWithValue(fetch),
      ],
      child: const MaterialApp(home: Scaffold(body: AppUpdateRow())),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a development build cannot update and says so', (tester) async {
    await _pump(tester, version: '', fetch: () async => null);
    expect(find.text('App updates'), findsOneWidget);
    expect(find.text('Development build: no updates'), findsOneWidget);
  });

  testWidgets('tap when up to date: "You have the latest version"', (
    tester,
  ) async {
    await _pump(
      tester,
      version: '1.0.0-beta.3',
      fetch: () async => _release('1.0.0-beta.3'),
    );
    expect(find.text('Version 1.0.0-beta.3 · Tap to check'), findsOneWidget);

    await tester.tap(find.text('App updates'));
    await tester.pumpAndSettle();
    expect(find.text('You have the latest version.'), findsOneWidget);
    expect(find.text('Up to date · Version 1.0.0-beta.3'), findsOneWidget);
  });

  testWidgets('offline: says the check failed, not "up to date"', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      version: '1.0.0-beta.3',
      fetch: () async {
        // The start-up check succeeds quietly; the tap fails.
        if (calls++ == 0) return _release('1.0.0-beta.3');
        throw Exception('offline');
      },
    );
    await tester.tap(find.text('App updates'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not check for updates'), findsOneWidget);
    expect(find.textContaining('Up to date'), findsNothing);
  });

  testWidgets('a newer version found at start-up shows on the row', (
    tester,
  ) async {
    await _pump(
      tester,
      version: '1.0.0-beta.3',
      fetch: () async => _release('1.0.0-beta.4'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Version 1.0.0-beta.4 is ready · Tap to update'),
      findsOneWidget,
    );
  });

  test('updateCheckProvider: newer, same, and unreachable', () async {
    ProviderContainer make(Future<Map<String, dynamic>?> Function() f) {
      final c = ProviderContainer(
        overrides: [
          currentVersionProvider.overrideWithValue('1.0.0-beta.3'),
          latestReleaseFetcherProvider.overrideWithValue(f),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    final newer = await make(
      () async => _release('1.0.0'),
    ).read(updateCheckProvider)();
    expect(newer!.version, '1.0.0');
    expect(
      await make(
        () async => _release('1.0.0-beta.3'),
      ).read(updateCheckProvider)(),
      isNull,
    );
    expect(
      make(() async => null).read(updateCheckProvider)(),
      throwsA(isA<UpdateCheckFailed>()),
    );
  });
}
