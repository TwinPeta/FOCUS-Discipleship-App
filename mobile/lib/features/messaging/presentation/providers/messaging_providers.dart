import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/message.dart';
import '../../domain/thread.dart';
import 'moderation_providers.dart';

/// Threads ordered by last activity, with blocked participants removed.
final threadsProvider = FutureProvider<List<Thread>>((ref) async {
  final blocked = await ref.watch(blockedUserIdsProvider.future);
  final threads = await ref.watch(threadRepositoryProvider).getThreads();
  return threads.where((t) => !blocked.contains(t.participant.id)).toList();
});

/// Null for an unknown thread or one whose participant is blocked, so a
/// deep link can't reopen a blocked conversation.
final threadByIdProvider = FutureProvider.autoDispose.family<Thread?, String>((
  ref,
  id,
) async {
  final blocked = await ref.watch(blockedUserIdsProvider.future);
  final thread = await ref.watch(threadRepositoryProvider).getThreadById(id);
  if (thread == null || blocked.contains(thread.participant.id)) return null;
  return thread;
});

class ThreadMessagesController
    extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String threadId) {
    return ref.watch(messageRepositoryProvider).getMessages(threadId);
  }

  void _replace(String id, Message message) {
    final updated = <Message>[...state.valueOrNull ?? const <Message>[]];
    final index = updated.indexWhere((m) => m.id == id);
    if (index == -1) {
      updated.add(message);
    } else {
      updated[index] = message;
    }
    state = AsyncValue.data(updated);
  }

  /// Appends a `sending` bubble, then swaps it for the stored message, or
  /// marks it `failed` (tap to retry) if the repository throws.
  Future<void> send(String text) async {
    final optimistic = Message(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      threadId: arg,
      senderId: Message.meId,
      text: text,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    _replace(optimistic.id, optimistic);
    await _deliver(optimistic);
  }

  /// Re-sends a failed message in place.
  Future<void> retry(String messageId) async {
    final failed = state.valueOrNull
        ?.where((m) => m.id == messageId && m.status == MessageStatus.failed)
        .firstOrNull;
    if (failed == null) return;
    final sending = failed.copyWith(status: MessageStatus.sending);
    _replace(messageId, sending);
    await _deliver(sending);
  }

  Future<void> _deliver(Message pending) async {
    try {
      final sent = await ref
          .read(messageRepositoryProvider)
          .sendMessage(arg, pending.text);
      _replace(pending.id, sent);
      ref.invalidate(threadsProvider);
    } catch (_) {
      _replace(pending.id, pending.copyWith(status: MessageStatus.failed));
    }
  }
}

final threadMessagesProvider =
    AsyncNotifierProvider.family<
      ThreadMessagesController,
      List<Message>,
      String
    >(ThreadMessagesController.new);
