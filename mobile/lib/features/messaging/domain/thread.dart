import '../../community/domain/person.dart';

class Thread {
  const Thread({
    required this.id,
    required this.participant,
    required this.roleLabel,
    this.lastMessage = '',
    required this.lastAt,
    this.unread = 0,
  });

  final String id;
  final Person participant;
  final String roleLabel;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;

  Thread copyWith({String? lastMessage, DateTime? lastAt, int? unread}) {
    return Thread(
      id: id,
      participant: participant,
      roleLabel: roleLabel,
      lastMessage: lastMessage ?? this.lastMessage,
      lastAt: lastAt ?? this.lastAt,
      unread: unread ?? this.unread,
    );
  }
}
