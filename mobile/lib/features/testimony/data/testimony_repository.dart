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
  Future<Testimony> submitStory(Testimony testimony);

  /// One testimony, or null unless it is reviewed or written by [viewerId]
  /// (and not hidden, nor by someone the viewer blocked).
  Future<Testimony?> getTestimony(String id, {required String? viewerId});

  /// Sets the viewer's "Encouraged" reaction. Idempotent.
  Future<Testimony> setEncouraged(String id, {required bool encouraged});
}
