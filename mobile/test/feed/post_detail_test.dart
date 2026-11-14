import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/connectivity/connectivity_service.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/core/widgets/states/offline_banner.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/community/data/membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/data/post_repository.dart';
import 'package:focus_1/features/feed/domain/comment.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/feed/presentation/providers/feed_providers.dart';
import 'package:focus_1/features/messaging/data/moderation_repository.dart';
import 'package:focus_1/features/messaging/presentation/providers/moderation_providers.dart';
import 'package:focus_1/features/profile/data/profile_repository.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

class _FailingPostRepo extends FakePostRepository {
  _FailingPostRepo() : super(latency: Duration.zero);

  @override
  Future<Post> setLiked(String postId, {required bool liked}) =>
      Future.error(Exception('offline'));

  @override
  Future<Comment> addComment(String postId, Comment comment) =>
      Future.error(Exception('offline'));
}

ProviderContainer _container({
  PostRepository? posts,
  ModerationRepository? moderation,
}) {
  final c = ProviderContainer(
    overrides: [
      postRepositoryProvider.overrideWith(
        (ref) => posts ?? FakePostRepository(latency: Duration.zero),
      ),
      moderationRepositoryProvider.overrideWith(
        (ref) => moderation ?? FakeModerationRepository(),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('PostRepository & providers (Screen 39)', () {
    test('getPostById resolves a deep-linked seeded post and null for unknown', () async {
      final repo = FakePostRepository(latency: Duration.zero);
      final post = await repo.getPostById('growth-circle-post-1');
      expect(post, isNotNull);
      expect(post!.communityId, 'growth-circle');

      final missing = await repo.getPostById('does-not-exist');
      expect(missing, isNull);
    });

    test('addComment is idempotent and chronological', () async {
      final repo = FakePostRepository(latency: Duration.zero);
      final before = await repo.getComments('growth-circle-post-1');
      final comment = Comment(
        id: 'c-new',
        postId: 'growth-circle-post-1',
        author: const Person(id: 'me', name: 'Me', role: PersonRole.member),
        body: 'Amen!',
        createdAt: DateTime.now(),
      );
      await repo.addComment('growth-circle-post-1', comment);
      await repo.addComment('growth-circle-post-1', comment);

      final after = await repo.getComments('growth-circle-post-1');
      expect(after, hasLength(before.length + 1));
      expect(after.last.id, 'c-new');
    });

    test('postDetailProvider rolls back like on error', () async {
      final c = _container(posts: _FailingPostRepo());
      final before = await c.read(
        postDetailProvider('growth-circle-post-1').future,
      );
      expect(before, isNotNull);

      await expectLater(
        c.read(postDetailProvider('growth-circle-post-1').notifier).toggleLike(),
        throwsException,
      );

      final after = c.read(postDetailProvider('growth-circle-post-1')).value;
      expect(after!.likedByMe, before!.likedByMe);
      expect(after.likeCount, before.likeCount);
    });

    test('postCommentsProvider rolls back optimistic comment on error', () async {
      final c = _container(posts: _FailingPostRepo());
      final before = await c.read(
        postCommentsProvider('growth-circle-post-1').future,
      );

      await expectLater(
        c
            .read(postCommentsProvider('growth-circle-post-1').notifier)
            .addComment('Will fail'),
        throwsException,
      );

      final after = c.read(postCommentsProvider('growth-circle-post-1')).value;
      expect(after, hasLength(before.length));
    });

    test('blocked users are hidden from post detail and comments', () async {
      final mod = FakeModerationRepository();
      await mod.blockUser('m-1');
      final c = _container(moderation: mod);

      final comments = await c.read(
        postCommentsProvider('growth-circle-post-1').future,
      );
      expect(comments.any((item) => item.author.id == 'm-1'), isFalse);

      // Post authored by m-1 returns null when blocked.
      final blockedPost = await c.read(
        postDetailProvider('growth-circle-post-photo').future,
      );
      expect(blockedPost, isNull);
    });
  });

  group('PostDetailScreen widget', () {
    testWidgets('renders post, comments, likes, and submits comment', (
      tester,
    ) async {
      final app = await pumpFcuApp(tester, membership: MembershipStatus.approved);
      await goTo(tester, app, '/post/growth-circle-post-1');

      expect(find.text('Grace Namuli'), findsOneWidget);
      expect(find.textContaining('Growth Circle'), findsOneWidget);
      expect(find.textContaining('9 likes · 2 comments'), findsOneWidget);
      expect(find.textContaining('David Okello'), findsOneWidget);
      expect(find.textContaining('Faith Nabirye'), findsOneWidget);

      // Optimistic like
      await tester.tap(find.text('Like'));
      await settle(tester);
      expect(find.text('Liked'), findsOneWidget);
      expect(find.textContaining('10 likes · 2 comments'), findsOneWidget);

      // Submit a comment
      await tester.enterText(
        find.widgetWithText(TextField, 'Write a comment'),
        'Count me in too!',
      );
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send comment'));
      await settle(tester);

      expect(find.text('Count me in too!'), findsOneWidget);
      expect(find.textContaining('10 likes · 3 comments'), findsOneWidget);
    });

    testWidgets('disables like and comment input while offline (not hidden)', (
      tester,
    ) async {
      final auth = FakeAuthRepository(latency: Duration.zero)
        ..debugSeedAccount(testProfile.email, 'Password1234', testProfile.id)
        ..debugSignInAs(testProfile.email);
      final profiles = FakeProfileRepository(latency: Duration.zero);
      final memberships = FakeMembershipRepository(latency: Duration.zero);
      final connectivity = FakeConnectivityService(online: false);

      await tester.runAsync(() async {
        await profiles.createProfile(testProfile);
        await memberships.requestToJoin('growth-circle');
        await memberships.debugApprove();
        await memberships.markResultSeen();
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => auth),
          profileRepositoryProvider.overrideWith((ref) => profiles),
          membershipRepositoryProvider.overrideWith((ref) => memberships),
          connectivityServiceProvider.overrideWith((ref) => connectivity),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              routerConfig: ref.watch(routerProvider),
            ),
          ),
        ),
      );
      await settle(tester);
      await goTo(tester, container, '/post/growth-circle-post-1');

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('Comments are paused while offline.'), findsOneWidget);

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Write a comment'),
      );
      expect(field.enabled, isFalse);

      // Tapping Like while offline does not toggle.
      await tester.tap(find.text('Like'));
      await settle(tester);
      expect(find.text('Like'), findsOneWidget);
      expect(find.textContaining('9 likes'), findsOneWidget);
    });

    testWidgets('tapping Comment on FeedList opens /post/:id', (tester) async {
      final app = await pumpFcuApp(tester, membership: MembershipStatus.approved);
      await goTo(tester, app, '/community/growth-circle/feed');

      await tester.tap(find.text('Comment').first);
      await settle(tester, steps: 15);

      expect(find.text('Comments'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Write a comment'), findsOneWidget);
    });

    testWidgets('unknown post id shows empty state', (tester) async {
      final app = await pumpFcuApp(tester, membership: MembershipStatus.approved);
      await goTo(tester, app, '/post/missing-post');

      expect(find.text('Post not available'), findsOneWidget);
    });
  });
}
