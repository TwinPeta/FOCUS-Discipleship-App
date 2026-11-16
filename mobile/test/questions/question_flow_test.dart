import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/domain/post.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

const _q = 'How do you keep a daily Bible reading habit during exams?';

void main() {
  testWidgets('64/65/67: list, answer full screen, back on the question', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    await tester.runAsync(
      () => app
          .read(postRepositoryProvider)
          .createPost(
            Post(
              id: 'q-1',
              communityId: 'growth-circle',
              scope: PostScope.specific,
              author: const Person(
                id: 'm-1',
                name: 'David Okello',
                role: PersonRole.member,
              ),
              body: _q,
              createdAt: DateTime.now(),
              kind: PostKind.question,
            ),
          ),
    );

    // 67: the list with Answer and Pass.
    await goTo(tester, app, '/questions');
    await settle(tester, steps: 12);
    expect(find.text('Questions for you'), findsOneWidget);
    expect(find.text(_q), findsOneWidget);
    expect(find.textContaining('No answers yet'), findsOneWidget);

    // 64: the question page.
    await tester.tap(find.text(_q));
    await settle(tester, steps: 12);
    expect(find.text('Question'), findsOneWidget);
    expect(find.textContaining('Asked by David Okello'), findsOneWidget);
    expect(find.text('Write an answer…'), findsOneWidget);

    // 65: answer full screen; Post is off until there is text.
    await tester.tap(find.text('Write an answer…'));
    await settle(tester, steps: 12);
    expect(app.read(routerProvider).state.uri.path, '/post/q-1/answer');
    expect(find.text('Be kind and helpful'), findsOneWidget);
    final post = find.widgetWithText(FilledButton, 'Post');
    expect(tester.widget<FilledButton>(post).onPressed, isNull);
    await tester.enterText(
      find.byType(TextField),
      'Read one short psalm each morning.',
    );
    await tester.pump();
    await tester.tap(post);
    await settle(tester, steps: 12);

    expect(app.read(routerProvider).state.uri.path, '/post/q-1');
    expect(find.text('Read one short psalm each morning.'), findsOneWidget);
    expect(find.text('1 answer'), findsOneWidget);
  });

  testWidgets('67: Pass hides a question until Undo', (tester) async {
    final app = await pumpFcuApp(tester);
    await tester.runAsync(
      () => app
          .read(postRepositoryProvider)
          .createPost(
            Post(
              id: 'q-2',
              communityId: 'growth-circle',
              scope: PostScope.specific,
              author: const Person(
                id: 'm-1',
                name: 'David Okello',
                role: PersonRole.member,
              ),
              body: _q,
              createdAt: DateTime.now(),
              kind: PostKind.question,
            ),
          ),
    );
    await goTo(tester, app, '/questions');
    await settle(tester, steps: 12);
    await tester.tap(find.text('Pass'));
    await settle(tester);
    expect(find.text(_q), findsNothing);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text(_q), findsOneWidget);
  });
}
