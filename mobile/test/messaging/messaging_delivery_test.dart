import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/community/presentation/providers/community_providers.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/feed/presentation/providers/feed_providers.dart';
import 'package:focus_1/features/messaging/domain/message.dart';
import 'package:focus_1/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:focus_1/features/messaging/presentation/providers/moderation_providers.dart';

import '../support/fakes.dart';
import '../support/fake_backend.dart';

/// Fails the first [failures] sends, then behaves normally.
class _FlakyMessagingRepository extends FakeMessagingRepository {
  _FlakyMessagingRepository(this.failures) : super(latency: Duration.zero);
  int failures;

  @override
  Future<Message> sendMessage(
    String threadId,
    String text, {
    String? clientId,
  }) async {
    if (failures > 0) {
      failures--;
      throw Exception('network');
    }
    return super.sendMessage(threadId, text);
  }
}

ProviderContainer _container(List<Override> overrides) {
  final c = fakeContainer(
    overrides: [
      moderationRepositoryProvider.overrideWith(
        (ref) => FakeModerationRepository(),
      ),
      ...overrides,
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('threads are ordered by last activity', () async {
    final repo = FakeMessagingRepository(latency: Duration.zero);
    final c = _container([
      messagingRepositoryProvider.overrideWith((ref) => repo),
    ]);

    var threads = await c.read(threadsProvider.future);
    expect(threads.first.id, 'thread-sm-1');

    // A reply in the older thread moves it to the top.
    await repo.sendMessage('thread-m-1', 'Hello again');
    c.invalidate(threadsProvider);
    threads = await c.read(threadsProvider.future);
    expect(threads.first.id, 'thread-m-1');
  });

  test('a failed send is marked failed and can be retried', () async {
    final repo = _FlakyMessagingRepository(1);
    final c = _container([
      messagingRepositoryProvider.overrideWith((ref) => repo),
    ]);
    final provider = threadMessagesProvider('thread-m-1');
    await c.read(provider.future);

    await c.read(provider.notifier).send('Hi');
    var last = c.read(provider).value!.last;
    expect(last.status, MessageStatus.failed);

    await c.read(provider.notifier).retry(last.id);
    final messages = c.read(provider).value!;
    last = messages.last;
    expect(last.status, MessageStatus.sent);
    expect(messages.where((m) => m.text == 'Hi'), hasLength(1));
  });

  test('blocking hides the person from feeds and member lists too', () async {
    final c = _container([
      messagingRepositoryProvider.overrideWith(
        (ref) => FakeMessagingRepository(latency: Duration.zero),
      ),
      postRepositoryProvider.overrideWith(
        (ref) => FakePostRepository(latency: Duration.zero),
      ),
      communityRepositoryProvider.overrideWith(
        (ref) => FakeCommunityRepository(),
      ),
    ]);
    const key = (communityId: 'growth-circle', scope: PostScope.specific);
    final sub = c.listen(communityMembersProvider('growth-circle'), (_, _) {});
    addTearDown(sub.close);

    expect(
      (await c.read(feedPostsProvider(key).future))
          .any((p) => p.author.id == 'm-1'),
      isTrue,
    );
    await c.read(moderationActionsProvider).block('m-1');

    final posts = await c.read(feedPostsProvider(key).future);
    expect(posts.any((p) => p.author.id == 'm-1'), isFalse);
    final members = await c.read(
      communityMembersProvider('growth-circle').future,
    );
    expect(members.any((m) => m.id == 'm-1'), isFalse);
  });
}
