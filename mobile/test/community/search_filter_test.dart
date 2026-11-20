import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/presentation/communities_hub_screen.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/profile/presentation/profile_providers.dart';

import '../support/pump_utils.dart';
import '../support/fake_backend.dart';

class _FakeMembershipController extends MembershipController {
  @override
  Future<Membership> build() async => Membership.empty;
}

Widget _wrap() {
  return ProviderScope(
    overrides: [
      ...fakeBackend(),
      currentProfileProvider.overrideWith((ref) => testProfile),
      membershipProvider.overrideWith(_FakeMembershipController.new),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: GoRouter(
        initialLocation: '/x',
        routes: [
          GoRoute(
            path: '/x',
            builder: (context, state) => const CommunitiesHubScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('filters by name', (tester) async {
    await tester.pumpWidget(_wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField).last, 'growth');
    await settle(tester);

    expect(find.text('Growth Circle'), findsOneWidget);
    expect(find.text('Life & Faith Circle'), findsNothing);
    expect(find.text('Freshers Connect'), findsNothing);
  });

  testWidgets('filters by meeting day', (tester) async {
    await tester.pumpWidget(_wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField).last, 'friday');
    await settle(tester);

    expect(find.text('Freshers Connect'), findsOneWidget);
    expect(find.text('Growth Circle'), findsNothing);
  });

  testWidgets('filters by room/place', (tester) async {
    await tester.pumpWidget(_wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField).last, 'chapel');
    await settle(tester);

    expect(find.text('Life & Faith Circle'), findsOneWidget);
    expect(find.text('Growth Circle'), findsNothing);
  });

  testWidgets('shows an empty state when nothing matches', (tester) async {
    await tester.pumpWidget(_wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField).last, 'no such caregroup');
    await settle(tester);

    expect(find.text('No caregroups match your search.'), findsOneWidget);
  });
}
