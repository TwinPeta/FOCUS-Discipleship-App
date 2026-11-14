import '../../community/domain/person.dart';
import '../domain/message.dart';
import '../domain/thread.dart';

abstract class ThreadRepository {
  /// Threads belonging to blocked users are filtered out elsewhere (see
  /// `threadsProvider`), not in this method, so moderation stays a
  /// separate concern from thread storage.
  Future<List<Thread>> getThreads();
  Future<Thread?> getThreadById(String id);
  Future<Thread> openOrCreateThread(Person participant, String roleLabel);
  Future<void> markRead(String threadId);
}

abstract class MessageRepository {
  Future<List<Message>> getMessages(String threadId);
  Future<Message> sendMessage(String threadId, String text);
}

/// Backs both [ThreadRepository] and [MessageRepository] so a sent message
/// can update its thread's `lastMessage`/`lastAt` in one place.
class FakeMessagingRepository implements ThreadRepository, MessageRepository {
  static const _latency = Duration(milliseconds: 400);

  final List<Thread> _threads = [
    Thread(
      id: 'thread-sm-1',
      participant: const Person(
        id: 'sm-1',
        name: 'Grace Namuli',
        role: PersonRole.superMentor,
        online: true,
      ),
      roleLabel: 'Super-mentor',
      lastMessage: "Let me know if you can't make it on Tuesday!",
      lastAt: DateTime.now().subtract(const Duration(hours: 4)),
      unread: 2,
    ),
    Thread(
      id: 'thread-m-1',
      participant: const Person(
        id: 'm-1',
        name: 'David Okello',
        role: PersonRole.mentor,
      ),
      roleLabel: 'Mentor',
      lastMessage: 'Great seeing you at the meeting today.',
      lastAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final Map<String, List<Message>> _messages = {
    'thread-sm-1': [
      Message(
        id: 'thread-sm-1-m1',
        threadId: 'thread-sm-1',
        senderId: 'sm-1',
        text: 'Hi! Just checking in ahead of this week\'s meeting.',
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Message(
        id: 'thread-sm-1-m2',
        threadId: 'thread-sm-1',
        senderId: 'sm-1',
        text: "Let me know if you can't make it on Tuesday!",
        sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ],
    'thread-m-1': [
      Message(
        id: 'thread-m-1-m1',
        threadId: 'thread-m-1',
        senderId: 'm-1',
        text: 'Great seeing you at the meeting today.',
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  };

  @override
  Future<List<Thread>> getThreads() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_threads);
  }

  @override
  Future<Thread?> getThreadById(String id) async {
    await Future.delayed(_latency);
    for (final thread in _threads) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  @override
  Future<Thread> openOrCreateThread(Person participant, String roleLabel) async {
    await Future.delayed(_latency);
    for (final thread in _threads) {
      if (thread.participant.id == participant.id) return thread;
    }
    final thread = Thread(
      id: 'thread-${participant.id}',
      participant: participant,
      roleLabel: roleLabel,
      lastAt: DateTime.now(),
    );
    _threads.insert(0, thread);
    _messages[thread.id] = [];
    return thread;
  }

  @override
  Future<void> markRead(String threadId) async {
    await Future.delayed(_latency);
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _threads[index] = _threads[index].copyWith(unread: 0);
    }
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    await Future.delayed(_latency);
    return List.unmodifiable(_messages[threadId] ?? const []);
  }

  @override
  Future<Message> sendMessage(String threadId, String text) async {
    await Future.delayed(_latency);
    final message = Message(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      senderId: Message.meId,
      text: text,
      sentAt: DateTime.now(),
    );
    _messages.putIfAbsent(threadId, () => []).add(message);

    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _threads[index] = _threads[index].copyWith(
        lastMessage: text,
        lastAt: message.sentAt,
      );
    }
    return message;
  }
}
