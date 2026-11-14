class StoryVideo {
  const StoryVideo({
    required this.id,
    required this.quote,
    required this.authorName,
    required this.institution,
    required this.duration,
  });

  final String id;
  final String quote;
  final String authorName;
  final String institution;
  final String duration;

  StoryVideo copyWith({
    String? id,
    String? quote,
    String? authorName,
    String? institution,
    String? duration,
  }) {
    return StoryVideo(
      id: id ?? this.id,
      quote: quote ?? this.quote,
      authorName: authorName ?? this.authorName,
      institution: institution ?? this.institution,
      duration: duration ?? this.duration,
    );
  }
}
