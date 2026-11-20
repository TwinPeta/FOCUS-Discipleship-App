import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/data/post_repository.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/feed/presentation/providers/feed_providers.dart';

import '../support/fakes.dart';
import '../support/fake_backend.dart';

class _FailingLikes extends FakePostRepository {
  _FailingLikes() : super(latency: Duration.zero);
  @override
  Future<Post> setLiked(String postId, {required bool liked}) =>
      Future.error(Exception('offline'));
}

ProviderContainer _container(PostRepository repo) {
  final c = fakeContainer(
    overrides: [
      postRepositoryProvider.overrideWith((ref) => repo),
      moderationRepositoryProvider.overrideWith(
        (ref) => FakeModerationRepository(),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

const _general = (communityId: 'general-makerere', scope: PostScope.general);
const _specific = (communityId: 'growth-circle', scope: PostScope.specific);

Post _newPost(String id) => Post(
  id: id,
  communityId: _specific.communityId,
  scope: PostScope.specific,
  author: const Person(id: 'me', name: 'Me', role: PersonRole.member),
  body: 'Hello',
  createdAt: DateTime.now(),
);

void main() {
  test(
    'the General feed loads its posts (no specific-caregroup lookup)',
    () async {
      final c = _container(FakePostRepository(latency: Duration.zero));
      final posts = await c.read(feedPostsProvider(_general).future);
      expect(posts, isNotEmpty);
      expect(posts.every((p) => p.scope == PostScope.general), isTrue);
    },
  );

  test('a like is persisted with the intended value', () async {
    final repo = FakePostRepository(latency: Duration.zero);
    final c = _container(repo);
    final before = (await c.read(feedPostsProvider(_specific).future)).first;

    await c.read(feedPostsProvider(_specific).notifier).toggleLike(before.id);

    final stored = (await repo.getPosts(
      _specific.communityId,
      PostScope.specific,
    )).items.firstWhere((p) => p.id == before.id);
    expect(stored.likedByMe, isTrue);
    expect(stored.likeCount, before.likeCount + 1);

    // After a refresh the like is still there.
    await c.read(feedPostsProvider(_specific).notifier).refresh();
    final refreshed = c
        .read(feedPostsProvider(_specific))
        .value!
        .firstWhere((p) => p.id == before.id);
    expect(refreshed.likedByMe, isTrue);
  });

  test('setLiked is idempotent', () async {
    final repo = FakePostRepository(latency: Duration.zero);
    final first = (await repo.getPosts('c', PostScope.specific)).items.first;
    await repo.setLiked(first.id, liked: true);
    final again = await repo.setLiked(first.id, liked: true);
    expect(again.likeCount, first.likeCount + 1);
  });

  test('a failed like rolls back', () async {
    final c = _container(_FailingLikes());
    final before = (await c.read(feedPostsProvider(_specific).future)).first;
    await expectLater(
      c.read(feedPostsProvider(_specific).notifier).toggleLike(before.id),
      throwsException,
    );
    final after = c
        .read(feedPostsProvider(_specific))
        .value!
        .firstWhere((p) => p.id == before.id);
    expect(after.likedByMe, before.likedByMe);
    expect(after.likeCount, before.likeCount);
  });

  test('a new post appears exactly once, also after refresh', () async {
    final c = _container(FakePostRepository(latency: Duration.zero));
    await c.read(feedPostsProvider(_specific).future);
    final notifier = c.read(feedPostsProvider(_specific).notifier);

    await notifier.createPost(_newPost('p1'));
    await notifier.createPost(_newPost('p1')); // double submit
    expect(
      c.read(feedPostsProvider(_specific)).value!.where((p) => p.id == 'p1'),
      hasLength(1),
    );

    await notifier.refresh();
    expect(
      c.read(feedPostsProvider(_specific)).value!.where((p) => p.id == 'p1'),
      hasLength(1),
    );
  });

  test('pages are disjoint and newest first', () async {
    final repo = FakePostRepository(latency: Duration.zero);
    final page1 = await repo.getPosts('c', PostScope.specific, limit: 2);
    expect(page1.items, hasLength(2));
    expect(page1.nextCursor, isNotNull);
    final page2 = await repo.getPosts(
      'c',
      PostScope.specific,
      cursor: page1.nextCursor,
      limit: 2,
    );
    expect(page2.items.map((p) => p.id), isNot(contains(page1.items.first.id)));
  });
}
