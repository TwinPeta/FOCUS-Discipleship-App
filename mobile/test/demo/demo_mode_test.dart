import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/profile/presentation/profile_providers.dart';
import 'package:focus_1/demo/demo_mode.dart';

void main() {
  test('demo skips sign-up, verification and approval', () async {
    final container = ProviderContainer(overrides: await demoOverrides());
    addTearDown(container.dispose);

    final session = await container.read(authControllerProvider.future);
    expect(session?.email, 'demo@fcu.test');

    final profile = await container.read(profileControllerProvider.future);
    expect(profile?.fullName, 'Demo Student');

    final membership = await container.read(membershipProvider.future);
    expect(membership.status, MembershipStatus.approved);
    expect(membership.communityId, demoCommunityId);
    expect(membership.hasUnseenResult, isFalse, reason: 'no result screen');

    expect(
      container.read(initialLocationProvider),
      '/community/$demoCommunityId/feed',
    );
  });

  test('the normal build starts on the landing page', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(initialLocationProvider), '/');
    expect(kDemoMode, isFalse);
  });
}
