enum MessageStatus { sending, sent, failed }

/// Sent by the current user when [senderId] is [Message.meId].
class Message {
  const Message({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.status = MessageStatus.sent,
  });

  static const meId = 'me';

  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;

  bool get isMine => senderId == meId;

  Message copyWith({MessageStatus? status}) {
    return Message(
      id: id,
      threadId: threadId,
      senderId: senderId,
      text: text,
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }
}
