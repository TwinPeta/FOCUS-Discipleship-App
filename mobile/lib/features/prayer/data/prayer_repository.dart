import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/app_notification.dart';
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

class FakePrayerRepository implements PrayerRepository {
  FakePrayerRepository({
    this.latency = const Duration(milliseconds: 400),
    bool Function(String requestId)? isHidden,
    bool Function(String userId)? isBlocked,
    this.notifications,
  }) : _isHidden = isHidden ?? _never,
       _isBlocked = isBlocked ?? _never;

  final Duration latency;
  final NotificationRepository? notifications;

  /// Private owner of each request (named or anonymous). Never exposed.
  final Map<String, String> _ownerOf = {};
  final Map<String, List<PrayerResponse>> _responses = {};
  var _responseCounter = 0;

  /// Requests hidden by moderation never leave the repository.
  final bool Function(String requestId) _isHidden;

  /// Named requests by blocked people are left out (anonymous ones have no
  /// author id, so they cannot be matched).
  final bool Function(String userId) _isBlocked;
  static bool _never(String _) => false;

  final Map<String, List<PrayerRequest>> _byCommunity = {};

  List<PrayerRequest> _seed(String communityId) {
    final now = DateTime.now();
    return [
      PrayerRequest(
        id: '$communityId-prayer-1',
        communityId: communityId,
        authorId: 'sm-1',
        authorName: 'Grace Namuli',
        anonymous: false,
        body:
            'Praying for wisdom as I prepare this week\'s teaching. Please pray '
            'the words land well with everyone.',
        createdAt: now.subtract(const Duration(hours: 3)),
        prayedCount: 8,
      ),
      PrayerRequest(
        id: '$communityId-prayer-2',
        communityId: communityId,
        anonymous: true,
        body:
            'Going through a hard season at home and finding it difficult to '
            'focus on school. Please pray for peace and strength.',
        createdAt: now.subtract(const Duration(days: 1)),
        prayedCount: 14,
      ),
      PrayerRequest(
        id: '$communityId-prayer-3',
        communityId: communityId,
        authorId: 'member-1',
        authorName: 'Faith Nabirye',
        anonymous: false,
        body: 'Thankful for how my exams went. Praying for my family\'s health now.',
        createdAt: now.subtract(const Duration(days: 2)),
        prayedCount: 5,
      ),
    ];
  }

  @override
  Future<List<PrayerRequest>> getRequests(String communityId) async {
    await Future.delayed(latency);
    return List.unmodifiable(
      _byCommunity
          .putIfAbsent(communityId, () => _seed(communityId))
          .where(
            (r) =>
                !_isHidden(r.id) &&
                (r.authorId == null || !_isBlocked(r.authorId!)),
          ),
    );
  }

  @override
  Future<PrayerRequest> createRequest(
    PrayerRequest request, {
    String? ownerId,
  }) async {
    await Future.delayed(latency);
    final owner = ownerId ?? request.authorId;
    if (owner != null) _ownerOf.putIfAbsent(request.id, () => owner);
    final requests = _byCommunity.putIfAbsent(
      request.communityId,
      () => _seed(request.communityId),
    );
    final existing = requests.where((r) => r.id == request.id).firstOrNull;
    if (existing != null) return existing;
    requests.insert(0, request);
    return request;
  }

  @override
  Future<PrayerRequest> setPrayed(
    String requestId, {
    required bool prayed,
  }) async {
    await Future.delayed(latency);
    for (final requests in _byCommunity.values) {
      final index = requests.indexWhere((r) => r.id == requestId);
      if (index == -1) continue;
      final current = requests[index];
      if (current.prayedByMe == prayed) return current;
      final updated = current.copyWith(
        prayedByMe: prayed,
        prayedCount: current.prayedCount + (prayed ? 1 : -1),
      );
      requests[index] = updated;
      return updated;
    }
    throw ArgumentError('Unknown prayer request id: $requestId');
  }

  PrayerRequest? _find(String requestId) {
    for (final requests in _byCommunity.values) {
      final r = requests.where((x) => x.id == requestId).firstOrNull;
      if (r != null) return r;
    }
    return null;
  }

  @override
  Future<PrayerRequest?> getRequest(String requestId) async {
    await Future.delayed(latency);
    final r = _find(requestId) ?? _findInSeed(requestId);
    if (r == null || _isHidden(r.id)) return null;
    if (r.authorId != null && _isBlocked(r.authorId!)) return null;
    return r;
  }

  /// Seeds are created per community on first read; a deep link may arrive
  /// first, so look the community up from the id.
  PrayerRequest? _findInSeed(String requestId) {
    final cut = requestId.indexOf('-prayer-');
    if (cut <= 0) return null;
    final communityId = requestId.substring(0, cut);
    _byCommunity.putIfAbsent(communityId, () => _seed(communityId));
    return _find(requestId);
  }

  List<PrayerResponse> _responsesFor(String requestId) =>
      _responses.putIfAbsent(requestId, () {
        if (!requestId.endsWith('-prayer-1') &&
            !requestId.endsWith('-prayer-2')) {
          return <PrayerResponse>[];
        }
        final now = DateTime.now();
        return [
          PrayerResponse(
            id: '$requestId-response-1',
            requestId: requestId,
            authorId: 'm-1',
            authorName: 'David Okello',
            body: 'Praying with you. You are not alone in this.',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ];
      });

  @override
  Future<List<PrayerResponse>> getResponses(String requestId) async {
    await Future.delayed(latency);
    return List.unmodifiable(
      _responsesFor(requestId)
          .where((r) => r.authorId == null || !_isBlocked(r.authorId!)),
    );
  }

  @override
  Future<PrayerResponse> addResponse({
    required String requestId,
    required String body,
    required String authorId,
    required String authorName,
  }) async {
    await Future.delayed(latency);
    final request = _find(requestId) ?? _findInSeed(requestId);
    if (request == null) {
      throw ArgumentError.value(requestId, 'requestId', 'unknown request');
    }
    final text = body.trim();
    if (text.isEmpty) throw ArgumentError.value(body, 'body', 'empty');
    final owner = _ownerOf[requestId] ?? request.authorId;
    final response = PrayerResponse(
      id: '$requestId-r${++_responseCounter}',
      requestId: requestId,
      authorId: authorId,
      authorName: authorName,
      // The anonymous author stays anonymous in their own thread too.
      anonymous: request.anonymous && owner == authorId,
      body: text,
      createdAt: DateTime.now(),
    );
    _responsesFor(requestId).add(response);
    if (owner != null && owner != authorId) {
      await notifications?.add(
        recipientId: owner,
        type: NotificationType.prayerResponse,
        title: 'Someone responded to your prayer request',
        targetRoute: '/prayer/$requestId',
      );
    }
    return response;
  }
}
