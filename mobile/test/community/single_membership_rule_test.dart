import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/presentation/communities_hub_screen.dart';
import 'package:focus_1/features/community/presentation/community_detail_screen.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/profile/presentation/profile_providers.dart';

import '../support/pump_utils.dart';
import '../support/fake_backend.dart';

import 'package:focus_1/core/utils/meeting_dates.dart';

class _FakeMembershipController extends MembershipController {
  _FakeMembershipController(this.initial);
  final Membership initial;

  @override
  Future<Membership> build() async => initial;
}

Widget _wrapHub(Membership membership) {
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
          GoRoute(
            path: '/communities/:id',
            builder: (context, state) =>
                Scaffold(body: Text('DETAIL:${state.pathParameters['id']}')),
          ),
        ],
      ),
    ),
  );
}

Widget _wrapDetail(Membership membership, String communityId) {
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
            builder: (context, state) =>
                CommunityDetailScreen(communityId: communityId),
          ),
          GoRoute(
            path: '/communities',
            builder: (context, state) => const Scaffold(body: Text('HUB')),
          ),
          GoRoute(
            path: '/community/:id/feed',
            builder: (context, state) =>
                Scaffold(body: Text('FEED:${state.pathParameters['id']}')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets(
    'hub: while pending, other communities are locked and cannot be opened',
    (tester) async {
      await tester.pumpWidget(
        _wrapHub(
          const Membership(
            communityId: 'growth-circle',
            status: MembershipStatus.pending,
          ),
        ),
      );
      await settle(tester);

      // Still visible (at reduced opacity) but tapping must not navigate away.
      // Scroll it clear of the bottom bar, so the tap lands on the card.
      await tester.ensureVisible(find.text('Life & Faith Circle'));
      await settle(tester);
      await tester.tap(
        find.text('Life & Faith Circle'),
        warnIfMissed: false, // locked: the card ignores taps
      );
      await settle(tester);

      expect(find.textContaining('DETAIL:'), findsNothing);
      expect(find.text('Pending approval'), findsOneWidget);
    },
  );

  testWidgets('hub: the search field is disabled while pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapHub(
        const Membership(
          communityId: 'growth-circle',
          status: MembershipStatus.pending,
        ),
      ),
    );
    await settle(tester);

    final searchField = tester.widget<TextField>(find.byType(TextField).last);
    expect(searchField.enabled, isFalse);
  });

  testWidgets('detail: no join button while pending in another community', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapDetail(
        const Membership(
          communityId: 'growth-circle',
          status: MembershipStatus.pending,
        ),
        'life-faith-circle',
      ),
    );
    await settle(tester);

    expect(find.text('Request to join'), findsNothing);
    expect(find.text("You're already in Growth Circle"), findsOneWidget);
    expect(
      find.text('A student can be in only one specific community.'),
      findsOneWidget,
    );
  });

  testWidgets('detail: pending here shows the status and Cancel request', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapDetail(
        const Membership(
          communityId: 'growth-circle',
          status: MembershipStatus.pending,
        ),
        'growth-circle',
      ),
    );
    await settle(tester);

    expect(find.text('Request pending'), findsOneWidget);
    expect(find.text('Cancel request'), findsOneWidget);
    expect(find.text('Request to join'), findsNothing);
  });

  testWidgets('detail: a member here gets "Go to community"', (tester) async {
    await tester.pumpWidget(
      _wrapDetail(
        const Membership(
          communityId: 'growth-circle',
          status: MembershipStatus.approved,
        ),
        'growth-circle',
      ),
    );
    await settle(tester);

    expect(find.text("You're a member"), findsOneWidget);
    await tester.tap(find.text('Go to community'));
    await settle(tester);
    expect(find.text('FEED:growth-circle'), findsOneWidget);
  });

  test('next meeting date: today until it starts, else next week', () {
    // Tuesday 18 Nov 2025, 10:00.
    final tueMorning = DateTime(2025, 11, 18, 10);
    expect(
      nextMeetingDate('Every Tuesday', '5:00 PM', tueMorning),
      DateTime(2025, 11, 18),
    );
    expect(
      nextMeetingDate('Every Tuesday', '9:00 AM', tueMorning),
      DateTime(2025, 11, 25),
    );
    expect(
      nextMeetingDate('Every Friday', '4:00 PM', tueMorning),
      DateTime(2025, 11, 21),
    );
    expect(nextMeetingDate(null, '4:00 PM', tueMorning), isNull);
    expect(dayMonthLabel(DateTime(2025, 11, 21)), 'Friday 21 November');
  });

  testWidgets(
    'detail: Request to join is enabled when the user has no membership',
    (tester) async {
      await tester.pumpWidget(_wrapDetail(Membership.empty, 'growth-circle'));
      await settle(tester);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Request to join'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('Request to join'));
      await settle(tester);

      expect(find.text('HUB'), findsOneWidget);
    },
  );
}
