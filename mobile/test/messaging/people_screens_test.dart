import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/messaging/presentation/conversation_screen.dart';
import 'package:focus_1/features/messaging/presentation/new_message_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

void main() {
  testWidgets('43: a mentor profile, then block with undo', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/members/m-1');
    await settle(tester, steps: 10);

    expect(find.text('David Okello'), findsWidgets);
    expect(find.text('@david.okello'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Prayer partner'), findsOneWidget); // an earned badge
    expect(find.text('Quiz finisher'), findsNothing); // not earned
    expect(find.text('Message'), findsOneWidget);

    await tester.ensureVisible(find.text('Block'));
    await tester.tap(find.text('Block'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Block'));
    await settle(tester, steps: 15);

    expect(find.text('David Okello is blocked.'), findsOneWidget);
    expect(
      container.read(moderationRepositoryProvider).isBlocked('m-1'),
      isTrue,
    );

    await tester.tap(find.text('Undo'));
    await settle(tester, steps: 10);
    expect(
      container.read(moderationRepositoryProvider).isBlocked('m-1'),
      isFalse,
    );
    // The Messages badge reloads the conversation list after (un)blocking.
    await settle(tester, steps: 6);
  });

  testWidgets('43: your own profile has no Message, Report or Block', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/members/${testProfile.id}');
    await settle(tester, steps: 10);

    expect(find.text('@${testProfile.username}'), findsOneWidget);
    expect(find.text('Message'), findsNothing);
    expect(find.text('Report'), findsNothing);
    expect(find.text('Block'), findsNothing);
  });

  testWidgets('54: new message lists mentors and members, search filters, '
      'tap opens the thread', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/messages/new');
    await settle(tester, steps: 10);

    expect(find.text('Your mentors'), findsOneWidget);
    expect(find.text('Members of Growth Circle'), findsOneWidget);
    expect(find.text('Joy Atim'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'joy');
    await settle(tester);
    expect(find.text('Joy Atim'), findsOneWidget);
    expect(find.text('David Okello'), findsNothing);

    await tester.tap(find.text('Joy Atim'));
    await settle(tester, steps: 15);
    final conversation = tester.widget<ConversationScreen>(
      find.byType(ConversationScreen),
    );
    expect(conversation.threadId, 'thread-member-3');
    expect(find.byType(NewMessageScreen), findsNothing); // replaced
  });

  testWidgets('55: blocked users can be unblocked', (tester) async {
    final container = await pumpFcuApp(tester);
    await tester.runAsync(
      () => container.read(moderationRepositoryProvider).blockUser('member-2'),
    );
    await goTo(tester, container, '/settings/blocked');
    await settle(tester, steps: 10);

    expect(find.text('Peter Ssentongo'), findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await settle(tester, steps: 15);
    expect(find.text('No one is blocked'), findsOneWidget);
  });

  testWidgets('58: an empty inbox offers Find a member', (tester) async {
    final container = await pumpFcuApp(tester);
    await tester.runAsync(() async {
      final blocks = container.read(moderationRepositoryProvider);
      await blocks.blockUser('sm-1');
      await blocks.blockUser('m-1');
    });
    await goTo(tester, container, '/messages');
    await settle(tester, steps: 10);

    expect(find.text('No messages yet'), findsOneWidget);
    await tester.tap(find.text('Find a member'));
    await settle(tester, steps: 10);
    expect(find.byType(NewMessageScreen), findsOneWidget);
  });
}
