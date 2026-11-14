import '../domain/prayer_request.dart';

abstract class PrayerRepository {
  Future<List<PrayerRequest>> getRequests(String communityId);
  Future<PrayerRequest> createRequest(PrayerRequest request);

  /// Sets the current user's "I prayed" mark to [prayed]. Idempotent, so a
  /// user contributes at most one count to a request however often they tap.
  Future<PrayerRequest> setPrayed(String requestId, {required bool prayed});
}

class FakePrayerRepository implements PrayerRepository {
  FakePrayerRepository({
    this.latency = const Duration(milliseconds: 400),
    bool Function(String requestId)? isHidden,
  }) : _isHidden = isHidden ?? _never;

  final Duration latency;

  /// Requests hidden by moderation never leave the repository.
  final bool Function(String requestId) _isHidden;
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
          .where((r) => !_isHidden(r.id)),
    );
  }

  @override
  Future<PrayerRequest> createRequest(PrayerRequest request) async {
    await Future.delayed(latency);
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
}
