/// What happened. Badge rules match on this, never on display text.
enum ActivityType {
  videoWatched,
  devotionalRead,
  documentRead,
  quizCompleted,
  prayed,
  pathwayCompleted,
  meetingAttended,
}

class ActivityEvent {
  const ActivityEvent({
    required this.type,
    required this.label,
    required this.at,
    this.sourceId,
  });

  final ActivityType type;
  final String label;
  final DateTime at;

  /// The thing acted on (request id, step id…), used to record
  /// once-per-source events only once.
  final String? sourceId;
}
