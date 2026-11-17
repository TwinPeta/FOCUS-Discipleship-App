import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/messaging/data/messaging_repository.dart';
import 'package:focus_1/features/messaging/domain/message.dart';
import 'package:focus_1/features/messaging/domain/thread.dart';

class FakeMessagingRepository implements MessagingRepository {
  FakeMessagingRepository({
    this.latency = const Duration(milliseconds: 400),
    bool Function()? isRestricted,
    bool Function(String userId)? isBlocked,
  }) : _isRestricted = isRestricted ?? _never,
       _isBlocked = isBlocked ?? _nobody;

  static bool _never() => false;
  static bool _nobody(String _) => false;

  /// Threads with blocked people are hidden and cannot be written to.
  final bool Function(String userId) _isBlocked;

  final Duration latency;

  /// Whether the under-18 limit currently applies to the signed-in user.
  final bool Function() _isRestricted;

  @override
  bool canMessage(Person person) => !(_isRestricted() && person.isAdult);

  void _checkAllowed(Person person) {
    if (_isBlocked(person.id)) throw PersonBlocked(person.id);
    if (!canMessage(person)) throw const MessagingRestricted();
  }

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
    await Future.delayed(latency);
    // Most recent activity first.
    final sorted = [..._threads.where((t) => !_isBlocked(t.participant.id))]
      ..sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Thread?> getThreadById(String id) async {
    await Future.delayed(latency);
    for (final thread in _threads) {
      if (thread.id == id) {
        return _isBlocked(thread.participant.id) ? null : thread;
      }
    }
    return null;
  }

  @override
  Future<Thread> openOrCreateThread(
    Person participant,
    String roleLabel,
  ) async {
    await Future.delayed(latency);
    _checkAllowed(participant);
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
    await Future.delayed(latency);
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _threads[index] = _threads[index].copyWith(unread: 0);
    }
  }

  @override
  Future<List<Message>> getMessages(String threadId) async {
    await Future.delayed(latency);
    return List.unmodifiable(_messages[threadId] ?? const []);
  }

  @override
  Future<Message> sendMessage(
    String threadId,
    String text, {
    String? clientId,
  }) async {
    await Future.delayed(latency);
    final thread = _threads.where((t) => t.id == threadId).firstOrNull;
    if (thread != null) _checkAllowed(thread.participant);
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
