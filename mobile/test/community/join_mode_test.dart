import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/config/app_config.dart';
import 'package:focus_1/features/community/domain/membership.dart';

import '../support/app_harness.dart';

void main() {
  test('app config: auto-approval read from the server', () {
    expect(
      AppConfig.fromJson({
        'join_requests': {'auto_approve': true},
      }).autoApproveJoin,
      isTrue,
    );
    expect(
      AppConfig.fromJson({
        'join_requests': {'auto_approve': false},
      }).autoApproveJoin,
      isFalse,
    );
    expect(AppConfig.fromJson(null).autoApproveJoin, isFalse);
  });

  testWidgets('4: auto-approval on: "Join caregroup"; off: "Join"', (
    tester,
  ) async {
    final auto = await pumpFcuApp(
      tester,
      membership: MembershipStatus.none,
      overrides: [
        appConfigProvider.overrideWith(
          (ref) async => const AppConfig(autoApproveJoin: true),
        ),
      ],
    );
    await goTo(tester, auto, '/communities/life-faith-circle');
    expect(find.text('Join caregroup'), findsOneWidget);
    expect(find.textContaining('You join instantly'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('4: manual approval shows "Join" (3b pending flow)', (
    tester,
  ) async {
    final manual = await pumpFcuApp(tester, membership: MembershipStatus.none);
    await goTo(tester, manual, '/communities/life-faith-circle');
    expect(find.text('Join'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('3: unread chats show on the header chat icon and the '
      'Messages tab', (tester) async {
    final app = await pumpFcuApp(tester, membership: MembershipStatus.none);
    await goTo(tester, app, '/communities');
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.bySemanticsLabel(RegExp(r'^Messages, \d+ unread$')),
      findsNWidgets(2),
    );
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 2));
  });
}
