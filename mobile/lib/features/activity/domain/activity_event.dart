class ActivityEvent {
  const ActivityEvent({required this.type, required this.label, required this.at});

  /// A short machine key ('video_watched', 'quiz_completed', 'prayed',
  /// 'pathway_completed', 'meeting_attended', ...) that badge rules match on.
  final String type;
  final String label;
  final DateTime at;
}
