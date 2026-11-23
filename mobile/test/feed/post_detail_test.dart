import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/connectivity/connectivity_service.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/feed/data/post_repository.dart';
import 'package:focus_1/features/feed/domain/comment.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/feed/presentation/providers/feed_providers.dart';
import 'package:focus_1/features/feed/presentation/providers/post_detail_providers.dart';
import 'package:focus_1/features/messaging/data/moderation_repository.dart';
import 'package:focus_1/features/profile/presentation/profile_providers.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';
import '../support/fakes.dart';
import '../support/fake_backend.dart';

class _FailingComments extends FakePostRepository {
  _FailingComments() : super(latency: Duration.zero);
  @override
  Future<Comment> addComment(Comment comment) =>
      Future.error(Exception('offline'));
}

const _feed = (communityId: 'growth-circle', scope: PostScope.specific);
const _postId = 'growth-circle-post-1';

ProviderContainer _container(
  PostRepository repo, {
  ModerationRepository? moderation,
}) {
  final c = fakeContainer(
    overrides: [
      postRepositoryProvider.overrideWith((ref) => repo),
      moderationRepositoryProvider.overrideWith(
        (ref) => moderation ?? FakeModerationRepository(),
      ),
      currentProfileProvider.overrideWithValue(testProfile),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Loads the feed (so the post exists) and keeps the post providers alive.
Future<void> _open(ProviderContainer c) async {
  await c.read(feedPostsProvider(_feed).future);
  c.listen(postDetailProvider(_postId), (_, _) {});
  c.listen(postCommentsProvider(_postId), (_, _) {});
  await c.read(postDetailProvider(_postId).future);
  await c.read(postCommentsProvider(_postId).future);
}

Post _feedCopy(ProviderContainer c) =>
    c.read(feedPostsProvider(_feed)).value!.firstWhere((p) => p.id == _postId);

void main() {
  test('the comment count matches the stored comments', () async {
    final c = _container(FakePostRepository(latency: Duration.zero));
    await _open(c);
    expect(c.read(postDetailProvider(_postId)).value!.commentCount, 2);
    expect(c.read(postCommentsProvider(_postId)).value, hasLength(2));
  });

  test('comments from blocked users are hidden', () async {
    final moderation = FakeModerationRepository();
    await moderation.blockUser('member-2');
    final c = _container(
      FakePostRepository(latency: Duration.zero),
      moderation: moderation,
    );
    await _open(c);
    final comments = c.read(postCommentsProvider(_postId)).value!;
    expect(comments.map((x) => x.author.id), isNot(contains('member-2')));
    expect(comments, hasLength(1));
  });

  test(
    'a comment is optimistic and raises the count in the feed too',
    () async {
      final repo = FakePostRepository(latency: Duration.zero);
      final c = _container(repo);
      await _open(c);

      final pending = c
          .read(postCommentsProvider(_postId).notifier)
          .add('  Amen  ');
      // Visible before the repository answers.
      expect(c.read(postCommentsProvider(_postId)).value!.last.text, 'Amen');
      await pending;

      expect(c.read(postDetailProvider(_postId)).value!.commentCount, 3);
      expect(_feedCopy(c).commentCount, 3);
      expect(await repo.getComments(_postId), hasLength(3));
    },
  );

  test('a failed comment rolls back', () async {
    final c = _container(_FailingComments());
    await _open(c);
    await expectLater(
      c.read(postCommentsProvider(_postId).notifier).add('Hello'),
      throwsException,
    );
    expect(c.read(postCommentsProvider(_postId)).value, hasLength(2));
    expect(c.read(postDetailProvider(_postId)).value!.commentCount, 2);
  });

  test('a like on the post screen shows in the feed', () async {
    final c = _container(FakePostRepository(latency: Duration.zero));
    await _open(c);
    final before = _feedCopy(c);
    await c.read(postDetailProvider(_postId).notifier).toggleLike();
    expect(_feedCopy(c).likedByMe, isTrue);
    expect(_feedCopy(c).likeCount, before.likeCount + 1);
  });

  testWidgets('the post screen shows comments and disables input offline', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    // Load the feed first so the seeded post exists.
    await goTo(tester, container, '/community/growth-circle/feed');
    await goTo(tester, container, '/post/$_postId');

    expect(find.text('Post'), findsOneWidget);
    expect(find.textContaining('Room 204'), findsOneWidget);
    expect(find.text('Peter Ssentongo'), findsNothing); // inside a rich text
    expect(find.textContaining('Peter Ssentongo'), findsOneWidget);
    expect(find.bySemanticsLabel('Comments, 2'), findsOneWidget);
    expect(find.text('2 comments'), findsNothing);

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).enabled, isTrue);

    (container.read(connectivityServiceProvider) as FakeConnectivityService)
        .setOnline(false);
    await settle(tester);
    // Offline comments are saved and sent once back online.
    expect(tester.widget<TextField>(field).enabled, isTrue);
    expect(find.text('You are offline'), findsOneWidget); // the banner
    expect(find.text('Write a comment (sent when back online)'), findsOneWidget);
  });
}
