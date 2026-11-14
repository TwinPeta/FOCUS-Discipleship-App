import '../domain/prayer_request.dart';

abstract class PrayerRepository {
  Future<List<PrayerRequest>> getRequests(String communityId);
  Future<PrayerRequest> createRequest(PrayerRequest request);

  /// Toggles the current user's "I prayed" mark. A user can only ever
  /// contribute one count to a request, however many times they tap.
  Future<PrayerRequest> togglePrayed(String requestId);
}

class FakePrayerRepository implements PrayerRepository {
  static const _latency = Duration(milliseconds: 400);

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
    await Future.delayed(_latency);
    return _byCommunity.putIfAbsent(communityId, () => _seed(communityId));
  }

  @override
  Future<PrayerRequest> createRequest(PrayerRequest request) async {
    await Future.delayed(_latency);
    final requests = _byCommunity.putIfAbsent(request.communityId, () => []);
    requests.insert(0, request);
    return request;
  }

  @override
  Future<PrayerRequest> togglePrayed(String requestId) async {
    await Future.delayed(_latency);
    for (final requests in _byCommunity.values) {
      final index = requests.indexWhere((r) => r.id == requestId);
      if (index == -1) continue;
      final current = requests[index];
      final toggled = current.copyWith(
        prayedByMe: !current.prayedByMe,
        prayedCount: current.prayedByMe
            ? current.prayedCount - 1
            : current.prayedCount + 1,
      );
      requests[index] = toggled;
      return toggled;
    }
    throw ArgumentError('Unknown prayer request id: $requestId');
  }
}
