import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/widgets/placeholder_screen.dart';
import 'package:focus_1/core/widgets/round_icon_button.dart';
import 'package:focus_1/core/widgets/states/error_view.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

/// Batch 6 link and Back walk (Agent B).
///
/// Every screen of an approved member (and the super-mentor tools) is
/// opened two ways:
/// 1. as a deep link (nothing to pop), where Back must still land on a
///    working screen, never an error or a blank page;
/// 2. pushed from the screen that links to it, where Back must return to
///    exactly that screen.
/// Routes still owned by a later screen show `PlaceholderScreen`; they are
/// reported, not failed, until their owner lands them.

const _feed = '/community/growth-circle/feed';

/// (parent, child) pairs: the child is what a control on the parent opens.
const _legs = <(String, String)>[
  ('/communities', '/profile'),
  ('/communities', '/notifications'),
  ('/communities', '/communities/life-faith-circle'),
  ('/notifications', '/notifications/settings'),
  ('/profile', '/activity'),
  ('/profile', '/profile/edit'),
  ('/profile', '/settings'),
  ('/profile', '/settings/profile'),
  (_feed, '/create?type=post&to=growth-circle'),
  (_feed, '/post/growth-circle-post-1'),
  (_feed, '/messages'),
  ('/post/growth-circle-post-1', '/members/sm-1'),
  (
    '/post/growth-circle-post-1',
    '/report/post/growth-circle-post-1?name=Grace%20Namuli&back=%2Fcommunity%2Fgrowth-circle%2Ffeed',
  ),
  ('/community/growth-circle/prayer', '/create?type=prayer&to=growth-circle'),
  ('/community/growth-circle/prayer', '/prayer/growth-circle-prayer-1'),
  (
    '/community/growth-circle/testimonies',
    '/create?type=story&to=growth-circle',
  ),
  (
    '/community/growth-circle/testimonies',
    '/testimony/growth-circle-testimony-1',
  ),
  (
    '/community/growth-circle/pathways',
    '/community/growth-circle/pathways/pathway-1',
  ),
  (
    '/community/growth-circle/resources',
    '/resources/video/resource-1?community=growth-circle',
  ),
  ('/community/growth-circle/resources', '/devotional/resource-2'),
  ('/community/growth-circle/resources', '/quiz/resource-3'),
  ('/community/growth-circle/resources', '/document/resource-4'),
  ('/community/growth-circle/info', '/community/growth-circle/meetings'),
  ('/community/growth-circle/info', '/members/m-1'),
  ('/general-feed', '/create?type=post&to=general'),
  ('/general-feed', '/general-feed/prayer'),
  ('/general-feed', '/general-feed/testimonies'),
  ('/messages', '/messages/new'),
  ('/messages', '/messages/thread-sm-1'),
  ('/messages/thread-sm-1', '/messages/thread-sm-1/report'),
  ('/messages/thread-sm-1', '/members/sm-1'),
  (
    '/members/m-1',
    '/report/user/m-1?name=David%20Okello&back=%2Fmembers%2Fm-1',
  ),
  ('/settings/blocked', '/members/m-1'),
  ('/activity', '/badge/first-steps/earned'),
];

/// Deep links that only a super-mentor reaches.
const _superMentorLegs = <(String, String)>[
  (_feed, '/community/growth-circle/manage'),
  (
    '/community/growth-circle/manage',
    '/community/growth-circle/manage/requests',
  ),
  (
    '/community/growth-circle/manage',
    '/community/growth-circle/manage/reports',
  ),
];

/// Screens that are a root or a full-screen result: no Back control is
/// expected (they move on with their own buttons).
const _noBackExpected = {
  '/communities',
  '/badge/first-steps/earned',
  '/report/post/growth-circle-post-1/sent',
  '/messages/thread-sm-1/report/sent',
};

/// Deep links whose Back must reach a specific parent, not just "somewhere
/// that works". Screens not listed fall back to the hub.
const _deepBackParent = {
  '/post/growth-circle-post-1': _feed,
  '/report/post/growth-circle-post-1': _feed,
  '/report/user/m-1': '/members/m-1',
  '/community/growth-circle/pathways/pathway-1':
      '/community/growth-circle/pathways',
  '/activity': '/profile',
  '/messages/new': '/messages',
  '/messages/thread-sm-1': '/messages',
  '/messages/thread-sm-1/report': '/messages/thread-sm-1',
  '/notifications/settings': '/notifications',
  '/community/growth-circle/meetings': '/community/growth-circle/info',
  '/resources/video/resource-1': '/community/growth-circle/resources',
};

String _where(ProviderContainer c) {
  final config = c.read(routerProvider).routerDelegate.currentConfiguration;
  final last = config.lastOrNull;
  if (last is ImperativeRouteMatch) return last.matches.uri.toString();
  return config.uri.toString();
}

/// Drops the query, so `?back=` variants compare by screen.
String _path(String location) => Uri.parse(location).path;

Finder get _back => find.byWidgetPredicate(
  (w) =>
      (w is RoundIconButton &&
          (w.semanticLabel == 'Back' || w.semanticLabel == 'Close')) ||
      (w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Close')),
);

/// Presses Back; quiz Back asks first, so confirm "Leave".
Future<void> _pressBack(WidgetTester tester) async {
  await tester.tap(_back.first, warnIfMissed: false);
  await settle(tester, steps: 6);
  final leave = find.widgetWithText(TextButton, 'Leave');
  if (leave.evaluate().isNotEmpty) {
    await tester.tap(leave);
    await settle(tester, steps: 6);
  }
}

bool _onError() => find.byType(ErrorScreen).evaluate().isNotEmpty;
bool _onPlaceholder() => find.byType(PlaceholderScreen).evaluate().isNotEmpty;

void main() {
  testWidgets('every link resolves and every Back works (approved member)', (
    tester,
  ) async {
    final c = await pumpFcuApp(tester);
    final report = <String>[];
    final failures = <String>[];
    final placeholders = <String>{};

    Future<void> deepLink(String route) async {
      c.read(routerProvider).go(route);
      await settle(tester, steps: 14);
      final error = tester.takeException();
      if (error != null) failures.add('deep $route: threw $error');
      if (_onError()) failures.add('deep $route: error screen');
      if (_onPlaceholder()) placeholders.add(_path(route));
      if (_back.evaluate().isEmpty) {
        if (!_noBackExpected.contains(_path(route)) && !_onPlaceholder()) {
          failures.add('deep $route: no Back control');
        }
        return;
      }
      await _pressBack(tester);
      final after = _where(c);
      final backError = tester.takeException();
      if (backError != null) failures.add('deep $route Back: threw $backError');
      if (_onError()) failures.add('deep $route Back: error screen');
      final parent = _deepBackParent[_path(route)];
      if (parent != null && _path(after) != parent) {
        failures.add('deep $route Back: went to $after, expected $parent');
      }
      report.add('deep  $route  -> Back -> $after');
    }

    Future<void> pushed(String parent, String child) async {
      c.read(routerProvider).go(parent);
      await settle(tester, steps: 14);
      unawaited(c.read(routerProvider).push(child));
      await settle(tester, steps: 14);
      final error = tester.takeException();
      if (error != null) failures.add('push $child: threw $error');
      if (_onError()) failures.add('push $child: error screen');
      if (_onPlaceholder()) placeholders.add(_path(child));
      if (_back.evaluate().isEmpty) {
        if (!_noBackExpected.contains(_path(child))) {
          failures.add('push $parent > $child: no Back control');
        }
        return;
      }
      await _pressBack(tester);
      final after = _where(c);
      if (_path(after) != _path(parent)) {
        failures.add('push $parent > $child: Back went to $after');
      }
      report.add('push  $parent > $child  -> Back -> $after');
    }

    // Load the feed once so the seeded post exists for /post/:id.
    await deepLink(_feed);
    for (final (parent, child) in _legs) {
      await deepLink(child);
      await pushed(parent, child);
    }

    c.read(debugRoleOverrideProvider.notifier).state = UserRole.superMentor;
    for (final (parent, child) in _superMentorLegs) {
      await deepLink(child);
      await pushed(parent, child);
    }

    debugPrint(
      '--- link walk ---\n${report.join('\n')}\n'
      'placeholders (owner still building): ${placeholders.join(', ')}',
    );
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
