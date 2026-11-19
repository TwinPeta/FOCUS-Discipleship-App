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
  group('compareVersions', () {
    test('orders versions the semantic-versioning way', () {
      const ordered = [
        '0.9.9',
        '1.0.0-alpha',
        '1.0.0-beta.1',
        '1.0.0-beta.2',
        '1.0.0-beta.10',
        '1.0.0-rc.1',
        '1.0.0',
        '1.0.1',
        '1.2.0',
        '2.0.0',
      ];
      for (var i = 0; i < ordered.length - 1; i++) {
        expect(
          compareVersions(ordered[i], ordered[i + 1]),
          lessThan(0),
          reason: '${ordered[i]} < ${ordered[i + 1]}',
        );
        expect(compareVersions(ordered[i + 1], ordered[i]), greaterThan(0));
      }
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0.0+7', '1.0.0+3'), 0, reason: 'build ignored');
      expect(compareVersions('1.0', '1.0.0'), isNull);
      expect(compareVersions('android-build-25', '1.0.0'), isNull);
    });
  });

  group('parseLatestRelease', () {
    test('a newer version with fcu.apk is an update', () {
      final u = parseLatestRelease(
        _release('mobile-v1.0.0-beta.3'),
        current: '1.0.0-beta.2',
      );
      expect(u!.version, '1.0.0-beta.3');
      expect(u.downloadUrl, endsWith('/mobile-v1.0.0-beta.3/fcu.apk'));
    });

    test('same or older version, other tags, or no fcu.apk: no update', () {
      const current = '1.0.0-beta.2';
      expect(
        parseLatestRelease(_release('mobile-v1.0.0-beta.2'), current: current),
        isNull,
      );
      expect(
        parseLatestRelease(_release('mobile-v1.0.0-beta.1'), current: current),
        isNull,
      );
      expect(
        parseLatestRelease(_release('android-build-99'), current: current),
        isNull,
      );
      expect(
        parseLatestRelease(_release('mobile-vnext'), current: current),
        isNull,
      );
      expect(
        parseLatestRelease(
          _release('mobile-v1.0.0', asset: 'fcu-1.0.0.apk'),
          current: current,
        ),
        isNull,
        reason: 'only the fcu.apk asset is offered',
      );
    });
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required String current,
    required Map<String, dynamic>? latest,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentVersionProvider.overrideWithValue(current),
          latestReleaseFetcherProvider.overrideWithValue(() async => latest),
        ],
        child: const MaterialApp(home: Scaffold(body: UpdateBanner())),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('banner shows when a newer version exists', (tester) async {
    await pumpBanner(
      tester,
      current: '1.0.0-beta.2',
      latest: _release('mobile-v1.0.0-beta.3'),
    );
    expect(find.text('FCU 1.0.0-beta.3 is ready to install.'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('no banner when up to date or a local build', (tester) async {
    await pumpBanner(
      tester,
      current: '1.0.0-beta.3',
      latest: _release('mobile-v1.0.0-beta.3'),
    );
    expect(find.text('Download'), findsNothing);
    await pumpBanner(
      tester,
      current: '',
      latest: _release('mobile-v1.0.0-beta.3'),
    );
    expect(find.text('Download'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
