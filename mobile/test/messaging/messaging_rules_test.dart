import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/messaging/data/messaging_repository.dart';
import 'package:focus_1/features/messaging/data/moderation_repository.dart';
import 'package:focus_1/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:focus_1/features/messaging/presentation/providers/moderation_providers.dart';

void main() {
  test('sending a message appends it and updates the thread preview', () async {
    final container = ProviderContainer(
      overrides: [
        messagingRepositoryProvider.overrideWith(
          (ref) => FakeMessagingRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final before = await container.read(
      threadMessagesProvider('thread-m-1').future,
    );
    expect(before, hasLength(1));

    await container
        .read(threadMessagesProvider('thread-m-1').notifier)
        .send('On my way!');

    final after = container.read(threadMessagesProvider('thread-m-1')).value!;
    expect(after, hasLength(2));
    expect(after.last.text, 'On my way!');
    expect(after.last.isMine, isTrue);

    final threads = await container.read(threadRepositoryProvider).getThreads();
    final thread = threads.firstWhere((t) => t.id == 'thread-m-1');
    expect(thread.lastMessage, 'On my way!');
  });

  test('marking a thread read clears its unread count', () async {
    final container = ProviderContainer(
      overrides: [
        messagingRepositoryProvider.overrideWith(
          (ref) => FakeMessagingRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final before = await container.read(threadsProvider.future);
    final unreadThread = before.firstWhere((t) => t.id == 'thread-sm-1');
    expect(unreadThread.unread, greaterThan(0));

    await container.read(threadRepositoryProvider).markRead('thread-sm-1');
    container.invalidate(threadsProvider);
    final after = await container.read(threadsProvider.future);
    expect(after.firstWhere((t) => t.id == 'thread-sm-1').unread, 0);
  });

  test('blocking a user hides their thread from the inbox', () async {
    final container = ProviderContainer(
      overrides: [
        messagingRepositoryProvider.overrideWith(
          (ref) => FakeMessagingRepository(),
        ),
        moderationRepositoryProvider.overrideWith(
          (ref) => FakeModerationRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final before = await container.read(threadsProvider.future);
    expect(before.any((t) => t.id == 'thread-sm-1'), isTrue);

    await container.read(moderationActionsProvider).block('sm-1');
    final after = await container.read(threadsProvider.future);
    expect(after.any((t) => t.id == 'thread-sm-1'), isFalse);
    // A deep link to the blocked conversation resolves to nothing.
    expect(
      await container.read(threadByIdProvider('thread-sm-1').future),
      isNull,
    );
  });
}
