enum TestimonyType { video, story }

enum TestimonyStatus { pending, reviewed }

class Testimony {
  const Testimony({
    required this.id,
    required this.communityId,
    required this.type,
    required this.title,
    this.excerpt,
    required this.authorName,
    required this.institution,
    this.duration,
    required this.status,
    required this.createdAt,
    this.isMine = false,
  });

  final String id;
  final String communityId;
  final TestimonyType type;
  final String title;
  final String? excerpt;
  final String authorName;
  final String institution;
  final String? duration;
  final TestimonyStatus status;
  final DateTime createdAt;
  final bool isMine;
}
