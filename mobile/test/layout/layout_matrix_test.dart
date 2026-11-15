import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/features/community/domain/membership.dart';

import 'package:focus_1/features/auth/presentation/providers/auth_providers.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

/// Every screen in scope, at 320x568 / 390x844 / 430x932 and text scale
/// 1.0 / 1.3 / 2.0, must lay out without overflow or any other error.
const _sizes = {
  '320x568': Size(320, 568),
  '390x844': Size(390, 844),
  '430x932': Size(430, 932),
};
const _scales = [1.0, 1.3, 2.0];

const _approvedRoutes = [
  '/',
  '/join',
  '/profile',
  '/profile/edit',
  '/communities',
  '/communities/life-faith-circle',
  '/community/growth-circle/feed',
  '/community/growth-circle/prayer',
  '/community/growth-circle/testimonies',
  '/community/growth-circle/pathways',
  '/community/growth-circle/resources',
  '/community/growth-circle/info',
  '/community/growth-circle/compose',
  '/community/growth-circle/prayer/new',
  '/community/growth-circle/testimonies/new',
  '/community/growth-circle/pathways/pathway-1',
  '/community/growth-circle/pathways/pathway-3',
  '/general-feed',
  '/general-feed/compose',
  '/messages',
  '/messages/thread-sm-1',
  '/messages/thread-sm-1/report',
  '/messages/thread-sm-1/report/sent',
  '/post/growth-circle-post-1',
  '/members/m-1',
  '/messages/new',
  '/settings/blocked',
  '/report/post/growth-circle-post-1?name=Grace%20Namuli&back=%2Fcommunity%2Fgrowth-circle%2Ffeed',
  '/report/post/growth-circle-post-1/sent?back=%2Fcommunity%2Fgrowth-circle%2Ffeed',
  '/activity',
  '/resources/video/resource-1?community=growth-circle',
  '/devotional/resource-2',
  '/quiz/resource-3',
  '/document/resource-4',
  '/resources/video/pathway-1-step-4?pathway=pathway-1&community=growth-circle',
  '/badge/first-steps/earned',
  '/login',
  '/nope',
];

const _signedOutRoutes = [
  '/',
  '/join',
  '/login',
  '/forgot-password',
  '/charter',
];

/// Screens whose content depends on not having a specific community yet.
const _noneRoutes = ['/communities', '/communities/growth-circle'];
const _pendingRoutes = ['/communities'];

void main() {
  for (final size in _sizes.entries) {
    for (final scale in _scales) {
      testWidgets('no layout errors at ${size.key} x$scale', (tester) async {
        final failures = <String>[];

        Future<void> sweepSignedOut() async {
          final app = await pumpFcuApp(
            tester,
            membership: MembershipStatus.none,
            size: size.value,
            textScale: scale,
            signedIn: false,
          );
          for (final route in _signedOutRoutes) {
            await goTo(tester, app, route);
            final error = tester.takeException();
            if (error != null) failures.add('[signed out] $route: $error');
          }
          // The sign-up steps need a draft to be reachable.
          app.read(signUpControllerProvider.notifier)
            ..setDetails(testProfile)
            ..setPassword('letters1234')
            ..markVerified();
          for (final route in [
            '/join/password',
            '/join/verify',
            '/join/consent',
            '/',
          ]) {
            await goTo(tester, app, route);
            final error = tester.takeException();
            if (error != null) failures.add('[sign-up] $route: $error');
          }
        }

        Future<void> sweep(MembershipStatus status, List<String> routes) async {
          final app = await pumpFcuApp(
            tester,
            membership: status,
            size: size.value,
            textScale: scale,
          );
          for (final route in routes) {
            await goTo(tester, app, route);
            final error = tester.takeException();
            if (error != null) {
              failures.add('[${status.name}] $route: $error');
            }
          }
        }

        await sweep(MembershipStatus.approved, _approvedRoutes);
        await sweepSignedOut();
        await sweep(MembershipStatus.none, _noneRoutes);
        await sweep(MembershipStatus.pending, _pendingRoutes);
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }

  testWidgets('forms stay usable with the keyboard open (320x568 x2.0)', (
    tester,
  ) async {
    final app = await pumpFcuApp(
      tester,
      size: const Size(320, 568),
      textScale: 2.0,
    );
    // A ~300px software keyboard.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    final failures = <String>[];
    for (final route in [
      '/join',
      '/profile/edit',
      '/community/growth-circle/compose',
      '/community/growth-circle/prayer/new',
      '/community/growth-circle/testimonies/new',
      '/messages/thread-sm-1',
      '/messages/thread-sm-1/report',
    ]) {
      await goTo(tester, app, route);
      final error = tester.takeException();
      if (error != null) failures.add('$route: $error');
    }
    expect(failures, isEmpty, reason: failures.join('; '));
  });
}
