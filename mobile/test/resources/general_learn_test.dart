import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/presentation/providers/community_providers.dart';
import 'package:focus_1/features/resources/presentation/general_resources_screen.dart';
import 'package:focus_1/features/resources/presentation/resources_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

void main() {
  // Learn needs no specific-community membership.
  for (final status in [MembershipStatus.none, MembershipStatus.approved]) {
    testWidgets(
      'Learn on the General feed opens General resources (${status.name})',
      (tester) async {
        final container = await pumpFcuApp(tester, membership: status);
        await goTo(tester, container, '/general-feed');
        await settle(tester, steps: 20);

        // Learn is in the header's "⋯" sections menu.
        await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
        await settle(tester);
        final learn = find.text('Learn');
        expect(learn, findsOneWidget);
        await tester.tap(learn);
        await settle(tester, steps: 12);

        expect(find.byType(GeneralResourcesScreen), findsOneWidget);
        final general = await container.read(generalCommunityProvider.future);
        final screen = tester.widget<ResourcesScreen>(
          find.byType(ResourcesScreen),
        );
        expect(screen.communityId, general.id);
        expect(screen.inCommunityShell, isFalse);
        expect(find.text('The faith of Abraham'), findsOneWidget);
      },
    );
  }

  testWidgets('/general-feed/resources opens directly (deep link)', (
    tester,
  ) async {
    final container = await pumpFcuApp(
      tester,
      membership: MembershipStatus.none,
    );
    await goTo(tester, container, '/general-feed/resources');
    await settle(tester, steps: 12);

    expect(find.byType(GeneralResourcesScreen), findsOneWidget);
    expect(find.text('The faith of Abraham'), findsOneWidget);
  });
}
