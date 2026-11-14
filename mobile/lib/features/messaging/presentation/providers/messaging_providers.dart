import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/message.dart';
import '../../domain/thread.dart';

/// Threads with any blocked participant filtered out — enforced here (the
/// data/provider layer), not just hidden in the UI.
final threadsProvider = FutureProvider<List<Thread>>((ref) async {
  final threads = await ref.watch(threadRepositoryProvider).getThreads();
  final blocked = await ref.watch(moderationRepositoryProvider).getBlockedUserIds();
  return threads.where((t) => !blocked.contains(t.participant.id)).toList();
});

final threadByIdProvider = FutureProvider.family<Thread?, String>((ref, id) {
  return ref.watch(threadRepositoryProvider).getThreadById(id);
});

class ThreadMessagesController extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String threadId) {
    return ref.watch(messageRepositoryProvider).getMessages(threadId);
  }

  Future<void> send(String text) async {
    final optimistic = Message(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      threadId: arg,
      senderId: Message.meId,
      text: text,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, optimistic]);

    final sent = await ref.read(messageRepositoryProvider).sendMessage(arg, text);

    final updated = <Message>[...state.valueOrNull ?? []];
    final index = updated.indexWhere((m) => m.id == optimistic.id);
    if (index != -1) {
      updated[index] = sent;
    } else {
      updated.add(sent);
    }
    state = AsyncValue.data(updated);
    ref.invalidate(threadsProvider);
  }
}

final threadMessagesProvider =
    AsyncNotifierProvider.family<ThreadMessagesController, List<Message>, String>(
  ThreadMessagesController.new,
);
