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
  _FakeMembershipController(this.initial);
  final Membership initial;

  @override
  Future<Membership> build() async => initial;
}

Widget _wrap(Membership membership) {
  return ProviderScope(
    overrides: [
      ...fakeBackend(),
      currentProfileProvider.overrideWith((ref) => testProfile),
      membershipProvider.overrideWith(
        () => _FakeMembershipController(membership),
      ),
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
  testWidgets('none state: dashed slot, banner and full list shown', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(Membership.empty));
    await settle(tester);

    expect(find.text('Specific community'), findsOneWidget);
    expect(find.text('Only 1 allowed · Pick below'), findsOneWidget);
    expect(find.text('Growth Circle'), findsOneWidget);
    expect(find.text('Life & Faith Circle'), findsOneWidget);
    expect(find.text('Freshers Connect'), findsOneWidget);
    expect(find.text('Prototype: super-mentor approves'), findsNothing);
  });

  testWidgets(
    'pending state: slot shows pending, requested community hidden from list',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Membership(
            communityId: 'growth-circle',
            status: MembershipStatus.pending,
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Pending approval'), findsOneWidget);
      // "Growth Circle" only appears once now: in the slot, not in the list below.
      expect(find.text('Growth Circle'), findsOneWidget);
      expect(find.text('Life & Faith Circle'), findsOneWidget);
      // The debug link moved to the debug scenario registry (prompt 2).
      expect(find.text('Prototype: super-mentor approves'), findsNothing);
    },
  );

  testWidgets('approved state: slot shows Joined, search and list are hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Membership(
          communityId: 'growth-circle',
          status: MembershipStatus.approved,
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Joined'), findsOneWidget);
    expect(find.text('Find a specific community'), findsNothing);
    expect(find.text('Life & Faith Circle'), findsNothing);
  });
}
