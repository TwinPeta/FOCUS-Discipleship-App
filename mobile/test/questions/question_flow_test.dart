import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/domain/comment.dart';
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

  testWidgets('64: Follow a question; mark an answer Helpful', (tester) async {
    final app = await pumpFcuApp(tester);
    await tester.runAsync(() async {
      final repo = app.read(postRepositoryProvider);
      await repo.createPost(
        Post(
          id: 'q-3',
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
      );
      await repo.addComment(
        Comment(
          id: 'a-1',
          postId: 'q-3',
          author: const Person(
            id: 'sm-1',
            name: 'Grace Namuli',
            role: PersonRole.superMentor,
          ),
          text: 'Read one psalm before breakfast.',
          createdAt: DateTime.now(),
        ),
      );
    });
    await goTo(tester, app, '/post/q-3');
    await settle(tester, steps: 12);

    await tester.tap(find.text('Follow'));
    await settle(tester);
    expect(find.text('Following'), findsOneWidget);
    expect(find.textContaining('1 follower'), findsOneWidget);
    await tester.tap(find.text('Following'));
    await settle(tester);
    expect(find.text('Follow'), findsOneWidget);

    expect(find.text('Helpful'), findsOneWidget);
    await tester.tap(find.text('Helpful'));
    await settle(tester);
    expect(find.text('Helpful · 1'), findsOneWidget);
    await tester.tap(find.text('Helpful · 1'));
    await settle(tester);
    expect(find.text('Helpful'), findsOneWidget);
  });

  testWidgets('62: search finds posts and questions by their words', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    await tester.runAsync(
      () => app
          .read(postRepositoryProvider)
          .createPost(
            Post(
              id: 'q-4',
              communityId: 'growth-circle',
              scope: PostScope.specific,
              author: const Person(
                id: 'm-1',
                name: 'David Okello',
                role: PersonRole.member,
              ),
              body: 'Who knows a quiet room for revision?',
              createdAt: DateTime.now(),
              kind: PostKind.question,
            ),
          ),
    );
    await goTo(tester, app, '/search');
    await settle(tester, steps: 10);
    await tester.enterText(find.byType(TextField), 'quiet room');
    await settle(tester, steps: 40);
    expect(find.text('Posts'), findsOneWidget);
    expect(find.text('Who knows a quiet room for revision?'), findsOneWidget);
    await tester.tap(find.text('Who knows a quiet room for revision?'));
    await settle(tester, steps: 12);
    expect(app.read(routerProvider).state.uri.path, '/post/q-4');
  });
}
