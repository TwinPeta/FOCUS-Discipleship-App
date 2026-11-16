import '../domain/testimony.dart';

abstract class TestimonyRepository {
  /// Reviewed stories are visible to everyone; a pending story is visible
  /// only to the viewer who wrote it ([viewerId] == `authorId`).
  Future<List<Testimony>> getTestimonies(
    String communityId, {
    required String? viewerId,
  });

  /// Always stored as [TestimonyStatus.pending], whatever the caller sends;
  /// only moderation can mark a story reviewed.
  /// Sends a story for review, with an optional photo and video (at most
  /// 2 minutes) from this device.
  Future<Testimony> submitStory(
    Testimony testimony, {
    StoryAttachments attachments = StoryAttachments.none,
  });

  /// One testimony, or null unless it is reviewed or written by [viewerId]
  /// (and not hidden, nor by someone the viewer blocked).
  Future<Testimony?> getTestimony(String id, {required String? viewerId});

  /// Sets the viewer's "Encouraged" reaction. Idempotent.
  Future<Testimony> setEncouraged(String id, {required bool encouraged});
}

/// Files attached to a story when it is sent.
class StoryAttachments {
  const StoryAttachments({this.photoPath, this.videoPath, this.videoLength});

  static const none = StoryAttachments();

  final String? photoPath;
  final String? videoPath;
  final Duration? videoLength;

  bool get isEmpty => photoPath == null && videoPath == null;
}
