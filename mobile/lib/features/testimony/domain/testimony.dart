import '../../feed/domain/post.dart' show PostPhoto;

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
    this.encouragedCount = 0,
    this.encouragedByMe = false,
    this.videoUrl,
    this.photos = const [],
  });

  /// Where the story's video plays from (screen 16 allows one, ≤2 min).
  final String? videoUrl;

  /// The story's photos, shown under the text.
  final List<PostPhoto> photos;

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

  /// "Encouraged" reactions (screen 53); one per member.
  final int encouragedCount;
  final bool encouragedByMe;

  bool isAuthoredBy(String? userId) => userId != null && authorId == userId;

  Testimony withEncouraged(bool on) => Testimony(
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
    videoUrl: videoUrl,
    photos: photos,
    encouragedByMe: on,
    encouragedCount:
        encouragedCount + (on == encouragedByMe ? 0 : (on ? 1 : -1)),
  );

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
    videoUrl: videoUrl,
    photos: photos,
    encouragedCount: encouragedCount,
    encouragedByMe: encouragedByMe,
  );
}
