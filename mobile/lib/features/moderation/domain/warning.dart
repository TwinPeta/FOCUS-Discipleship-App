/// A moderator's warning to a member about content that was hidden. The
/// member sees it (screen 61, prompt 3) until they acknowledge it.
class Warning {
  const Warning({
    required this.id,
    required this.userId,
    required this.reason,
    required this.preview,
    required this.createdAt,
    this.acknowledged = false,
  });

  final String id;
  final String userId;
  final String reason;

  /// The hidden content, shown back to the member.
  final String preview;
  final DateTime createdAt;
  final bool acknowledged;

  Warning copyWith({bool? acknowledged}) => Warning(
    id: id,
    userId: userId,
    reason: reason,
    preview: preview,
    createdAt: createdAt,
    acknowledged: acknowledged ?? this.acknowledged,
  );
}
