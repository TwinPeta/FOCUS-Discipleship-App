enum TestimonyType { video, story }

enum TestimonyStatus { pending, reviewed }

class Testimony {
  const Testimony({
    required this.id,
    required this.communityId,
    required this.type,
    required this.title,
    this.excerpt,
    this.authorId,
    required this.authorName,
    required this.institution,
    this.duration,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String communityId;
  final TestimonyType type;
  final String title;
  final String? excerpt;

  /// Null only for seeded/legacy stories. Visibility of pending stories is
  /// decided by comparing this with the viewer's id, never by a client flag.
  final String? authorId;
  final String authorName;
  final String institution;
  final String? duration;
  final TestimonyStatus status;
  final DateTime createdAt;

  bool isAuthoredBy(String? userId) => userId != null && authorId == userId;

  Testimony withStatus(TestimonyStatus status) => Testimony(
    id: id,
    communityId: communityId,
    type: type,
    title: title,
    excerpt: excerpt,
    authorId: authorId,
    authorName: authorName,
    institution: institution,
    duration: duration,
    status: status,
    createdAt: createdAt,
  );
}
