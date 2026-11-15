class StoryVideo {
  const StoryVideo({
    required this.id,
    required this.quote,
    required this.authorName,
    required this.institution,
    required this.duration,
    this.videoUrl,
  });

  final String id;
  final String quote;
  final String authorName;
  final String institution;
  final String duration;

  /// Where the video plays (YouTube or other https link); null when the
  /// backend has none, then the landing page uses a curated fallback.
  final String? videoUrl;

  StoryVideo copyWith({
    String? id,
    String? quote,
    String? authorName,
    String? institution,
    String? duration,
    String? videoUrl,
  }) {
    return StoryVideo(
      id: id ?? this.id,
      quote: quote ?? this.quote,
      authorName: authorName ?? this.authorName,
      institution: institution ?? this.institution,
      duration: duration ?? this.duration,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}
