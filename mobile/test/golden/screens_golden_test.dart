import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/features/community/domain/membership.dart';

import '../support/app_harness.dart';

/// Regression baseline for screens 1-5 at 390x844, rendered with the
/// bundled Source Sans 3. Regenerate deliberately with:
///   flutter test test/golden --update-goldens
/// (Goldens are rasterised per platform; these were produced on Windows.)
void main() {
  const cases = <(String, String, MembershipStatus)>[
    ('01_landing', '/', MembershipStatus.none),
    ('02_join_form', '/join', MembershipStatus.none),
    ('03_hub', '/communities', MembershipStatus.none),
    (
      '04_community_detail',
      '/communities/growth-circle',
      MembershipStatus.none,
    ),
    (
      '05_community_feed',
      '/community/growth-circle/feed',
      MembershipStatus.approved,
    ),
  ];

  for (final (name, route, membership) in cases) {
    testWidgets('golden $name', (tester) async {
      final app = await pumpFcuApp(tester, membership: membership);
      await goTo(tester, app, route);
      // Chained fake-repository loads (community, blocks, posts): let every
      // one finish so the baseline shows content, not the skeleton.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
      // Let fake-repository latency timers started by the screen finish.
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
