import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/community/data/community_repository.dart';
import 'package:focus_1/features/community/data/member_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/profile/presentation/profile_providers.dart';
import 'package:focus_1/features/search/data/search_repository.dart';
import 'package:focus_1/features/search/presentation/search_providers.dart';
import 'package:focus_1/features/search/presentation/search_screen.dart';

import '../support/pump_utils.dart';

class _Approved extends MembershipController {
  @override
  Future<Membership> build() async => const Membership(
    communityId: 'growth-circle',
    status: MembershipStatus.approved,
  );
}

void main() {
  testWidgets('search shows communities and people, then opens a profile', (
    tester,
  ) async {
    final communities = FakeCommunityRepository();
    final repo = ClientSideSearchRepository(
      communities: communities,
      members: FakeMemberRepository(
        latency: Duration.zero,
        roster: communities.getMembers,
      ),
      isBlocked: (_) => false,
    );
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
        GoRoute(
          path: '/members/:id',
          builder: (_, state) => Text('member ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) => testProfile),
          membershipProvider.overrideWith(_Approved.new),
          searchRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'growth');
    await settle(tester, steps: 20);
    expect(find.text('Communities'), findsOneWidget);
    expect(find.text('Growth Circle'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'okello');
    await settle(tester, steps: 20);
    expect(find.text('People'), findsOneWidget);
    expect(find.text('David Okello'), findsOneWidget);

    await tester.tap(find.text('David Okello'));
    await settle(tester);
    expect(find.text('member m-1'), findsOneWidget);

    router.pop();
    await settle(tester);
    await tester.enterText(find.byType(TextField), '');
    await settle(tester, steps: 5);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('okello'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await settle(tester, steps: 20);
    expect(find.text('No results for “zzzz”'), findsOneWidget);
  });
}
