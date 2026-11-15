import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/update/app_update.dart';
import 'package:focus_1/core/widgets/update_banner.dart';

Map<String, dynamic> _release(String tag, {String asset = 'fcu.apk'}) => {
  'tag_name': tag,
  'assets': [
    {
      'name': asset,
      'browser_download_url':
          'https://github.com/TwinPeta/FOCUS-Discipleship-App/releases/download/$tag/$asset',
    },
  ],
};

void main() {
  group('parseLatestRelease', () {
    test('a newer android build with an apk is an update', () {
      final u = parseLatestRelease(_release('android-build-12'), current: 10);
      expect(u!.buildNumber, 12);
      expect(u.downloadUrl, endsWith('/android-build-12/fcu.apk'));
    });

    test('same or older build, other tags, or no apk: no update', () {
      expect(
        parseLatestRelease(_release('android-build-10'), current: 10),
        isNull,
      );
      expect(
        parseLatestRelease(_release('android-build-9'), current: 10),
        isNull,
      );
      expect(parseLatestRelease(_release('v1.2.0'), current: 1), isNull);
      expect(
        parseLatestRelease(
          _release('android-build-12', asset: 'notes.txt'),
          current: 10,
        ),
        isNull,
      );
    });
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required int current,
    required Map<String, dynamic>? latest,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentBuildNumberProvider.overrideWithValue(current),
          latestReleaseFetcherProvider.overrideWithValue(() async => latest),
        ],
        child: const MaterialApp(home: Scaffold(body: UpdateBanner())),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('banner shows when a newer build exists', (tester) async {
    await pumpBanner(tester, current: 5, latest: _release('android-build-6'));
    expect(find.textContaining('build 6'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('no banner when up to date or a local build', (tester) async {
    await pumpBanner(tester, current: 6, latest: _release('android-build-6'));
    expect(find.text('Download'), findsNothing);
    await pumpBanner(tester, current: 0, latest: _release('android-build-6'));
    expect(find.text('Download'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
