import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/widgets/round_icon_button.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/data/post_repository.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/messaging/domain/report.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';

const _feed = '/community/growth-circle/feed';

void main() {
  group('post repository', () {
    test(
      'a hidden post leaves the feed and the post screen; unhide restores',
      () async {
        final repo = FakePostRepository(latency: Duration.zero);
        final first = (await repo.getPosts(
          'c',
          PostScope.specific,
        )).items.first;

        await repo.hidePost(first.id);
        final page = await repo.getPosts('c', PostScope.specific);
        expect(page.items.map((p) => p.id), isNot(contains(first.id)));
        expect(await repo.getPost(first.id), isNull);

        await repo.unhidePost(first.id);
        expect(await repo.getPost(first.id), isNotNull);
      },
    );

    test('only the author can delete a post', () async {
      final repo = FakePostRepository(latency: Duration.zero);
      final first = (await repo.getPosts('c', PostScope.specific)).items.first;

      await expectLater(
        repo.deletePost(first.id, byUserId: 'someone-else'),
        throwsA(isA<PostPermissionDenied>()),
      );
      expect(await repo.getPost(first.id), isNotNull);

      await repo.deletePost(first.id, byUserId: first.author.id);
      expect(await repo.getPost(first.id), isNull);
    });
  });

  testWidgets('report a post: sheet -> report -> sent -> hide with undo', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, _feed);
    await settle(tester, steps: 10);

    await tester.tap(find.byTooltip('Post options').first);
    await settle(tester);
    expect(find.text('Report post'), findsOneWidget);
    expect(find.text('Hide this post'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Delete post'), findsNothing); // not the author

    await tester.tap(find.text('Report post'));
    await settle(tester);
    expect(find.text('Report this post'), findsOneWidget);
    expect(find.text('What is wrong?'), findsOneWidget);

    final send = find.widgetWithText(ElevatedButton, 'Send report');
    expect(tester.widget<ElevatedButton>(send).onPressed, isNull);
    await tester.tap(find.text('Breaking caregroup rules'));
    await settle(tester);
    await tester.tap(send);
    await settle(tester, steps: 20);
    expect(find.textContaining('not sent'), findsNothing);

    expect(find.text('Report sent'), findsOneWidget);
    final reports = (container.read(
      reportRepositoryProvider,
    ) as FakeReportRepository).reports;
    expect(reports, hasLength(1));
    expect(reports.single.targetType, ReportTargetType.post);
    expect(reports.single.targetId, 'growth-circle-post-1');
    expect(reports.single.targetUserId, 'sm-1');
    expect(reports.single.reason, ReportReason.breakingRules);

    // It reached the community's moderation queue (screen 32).
    final cases = await tester.runAsync(
      () => container
          .read(moderationQueueRepositoryProvider)
          .getOpenCases('growth-circle', actorRole: UserRole.superMentor),
    );
    final filed = cases!.singleWhere(
      (c) => c.targetId == 'growth-circle-post-1',
    );
    expect(filed.reportCount, 1);
    expect(filed.firstReporterName, testProfile.fullName);
    expect(filed.preview, contains('Room 204'));

    await tester.tap(find.text('Hide this post'));
    await settle(tester);
    expect(find.textContaining('meeting in Room 204'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.textContaining('meeting in Room 204'), findsOneWidget);
  });

  testWidgets('authors can delete their own post after confirming', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, _feed);
    await tester.runAsync(
      () => container
          .read(postRepositoryProvider)
          .createPost(
            Post(
              id: 'my-post',
              communityId: 'growth-circle',
              scope: PostScope.specific,
              author: Person(
                id: testProfile.id,
                name: testProfile.fullName,
                role: PersonRole.member,
              ),
              body: 'My own words',
              createdAt: DateTime.now(),
            ),
          ),
    );
    await goTo(tester, container, '/post/my-post');
    await settle(tester, steps: 10);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is RoundIconButton && w.semanticLabel == 'Post options',
      ),
    );
    await settle(tester);
    expect(find.text('Report post'), findsNothing);
    await tester.tap(find.text('Delete post'));
    await settle(tester);
    expect(find.text('Delete this post?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);

    expect(find.text('Post deleted'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => container.read(postRepositoryProvider).getPost('my-post'),
      ),
      isNull,
    );
  });

  testWidgets('prayer requests use the same report flow', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/community/growth-circle/prayer');
    await settle(tester, steps: 10);

    await tester.tap(find.byTooltip('Report prayer request').first);
    await settle(tester);
    expect(find.text('Report this prayer request'), findsOneWidget);

    // Nothing is sent empty: no reason, or "Something else" with no
    // words (spaces do not count), keeps Send off.
    ElevatedButton send() =>
        tester.widget(find.widgetWithText(ElevatedButton, 'Send report'));
    expect(send().onPressed, isNull, reason: 'no reason picked');
    await tester.tap(find.text('Something else'));
    await settle(tester);
    expect(send().onPressed, isNull, reason: 'Something else needs words');
    expect(find.text('Tell us what happened (required)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(send().onPressed, isNull, reason: 'blank is not words');
    await tester.enterText(find.byType(TextField), 'Asks for money');
    await tester.pump();
    expect(send().onPressed, isNotNull);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send report'));
    await settle(tester, steps: 20);

    expect(find.text('Report sent'), findsOneWidget);
    expect(find.text('Hide this post'), findsNothing);
    final report = (container.read(
      reportRepositoryProvider,
    ) as FakeReportRepository).reports.single;
    expect(report.targetType, ReportTargetType.prayerRequest);
    expect(report.details, 'Asks for money');

    await tester.tap(find.text('Back to caregroup'));
    await settle(tester);
    // Back on the wall: its title (and the header's section name).
    expect(find.text('Prayer wall'), findsWidgets);
  });
}
