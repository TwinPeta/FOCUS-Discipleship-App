import '../domain/prayer_request.dart';
import '../domain/prayer_response.dart';

abstract class PrayerRepository {
  Future<List<PrayerRequest>> getRequests(String communityId);

  /// [ownerId] is who wrote it. For anonymous requests it is kept inside the
  /// repository only (to notify the owner and keep their replies
  /// anonymous); it never appears on [PrayerRequest].
  Future<PrayerRequest> createRequest(PrayerRequest request, {String? ownerId});

  /// One request, or null if it does not exist or is hidden.
  Future<PrayerRequest?> getRequest(String requestId);

  /// Oldest first; responses by blocked people are left out.
  Future<List<PrayerResponse>> getResponses(String requestId);

  /// Adds a response. When the responder owns an anonymous request, the
  /// response is stored as anonymous too. Notifies the request's owner
  /// (never naming an anonymous owner anywhere).
  Future<PrayerResponse> addResponse({
    required String requestId,
    required String body,
    required String authorId,
    required String authorName,
  });

  /// Sets the current user's "I prayed" mark to [prayed]. Idempotent, so a
  /// user contributes at most one count to a request however often they tap.
  Future<PrayerRequest> setPrayed(String requestId, {required bool prayed});
}
