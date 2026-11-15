import '../../community/domain/person.dart';
import '../domain/message.dart';
import '../domain/thread.dart';

abstract class ThreadRepository {
  /// Most recent activity first. Threads belonging to blocked users are
  /// filtered out by `threadsProvider`, so moderation stays a separate
  /// concern from thread storage.
  Future<List<Thread>> getThreads();
  Future<Thread?> getThreadById(String id);

  /// Throws [MessagingRestricted] when the under-18 limit applies.
  Future<Thread> openOrCreateThread(Person participant, String roleLabel);
  Future<void> markRead(String threadId);

  /// False while the current user may not message [person] (under-18
  /// limit). The UI disables composers with [MessagingRestricted.message].
  bool canMessage(Person person);
}

/// The under-18 limit: no starting or replying to conversations with adults
/// until a guardian confirms.
class MessagingRestricted implements Exception {
  const MessagingRestricted();
  static const message = "Waiting for your guardian's confirmation";
  @override
  String toString() => 'MessagingRestricted';
}

abstract class MessageRepository {
  Future<List<Message>> getMessages(String threadId);

  /// Throws [MessagingRestricted] when the under-18 limit applies.
  Future<Message> sendMessage(String threadId, String text);
}

/// One store behind both interfaces, so a sent message can update its
/// thread's `lastMessage`/`lastAt` in one place.
abstract class MessagingRepository
    implements ThreadRepository, MessageRepository {}

/// Opening or writing to a conversation with someone you blocked.
class PersonBlocked implements Exception {
  const PersonBlocked(this.userId);
  final String userId;
  @override
  String toString() => 'PersonBlocked($userId)';
}
