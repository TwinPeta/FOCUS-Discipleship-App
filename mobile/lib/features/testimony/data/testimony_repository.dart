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
}

class FakeTestimonyRepository implements TestimonyRepository {
  FakeTestimonyRepository({
    this.latency = const Duration(milliseconds: 400),
    bool Function(String testimonyId)? isHidden,
  }) : _isHidden = isHidden ?? _never;

  final Duration latency;

  /// Testimonies a moderator hid for everyone.
  final bool Function(String testimonyId) _isHidden;
  static bool _never(String _) => false;

  final Map<String, List<Testimony>> _byCommunity = {};

  List<Testimony> _seed(String communityId) {
    final now = DateTime.now();
    return [
      Testimony(
        id: '$communityId-testimony-1',
        communityId: communityId,
        type: TestimonyType.video,
        title: 'How FCU became my second family',
        authorName: 'Patience Achieng',
        institution: 'Makerere University',
        duration: '2:10',
        status: TestimonyStatus.reviewed,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Testimony(
        id: '$communityId-testimony-2',
        communityId: communityId,
        type: TestimonyType.story,
        title: 'Finding peace after a hard semester',
        excerpt:
            'I walked into my first small group meeting not expecting much, but '
            'the people there walked with me through the hardest months of my '
            'degree. I am not the same person I was a year ago.',
        authorName: 'David Okello',
        institution: 'Makerere University',
        status: TestimonyStatus.reviewed,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  @override
  Future<List<Testimony>> getTestimonies(
    String communityId, {
    required String? viewerId,
  }) async {
    await Future.delayed(latency);
    final all = _byCommunity.putIfAbsent(communityId, () => _seed(communityId));
    return List.unmodifiable(
      all.where(
        (t) =>
            !_isHidden(t.id) &&
            (t.status == TestimonyStatus.reviewed || t.isAuthoredBy(viewerId)),
      ),
    );
  }

  @override
  Future<Testimony> submitStory(Testimony testimony) async {
    await Future.delayed(latency);
    final list = _byCommunity.putIfAbsent(
      testimony.communityId,
      () => _seed(testimony.communityId),
    );
    final existing = list.where((t) => t.id == testimony.id).firstOrNull;
    if (existing != null) return existing;
    final stored = testimony.withStatus(TestimonyStatus.pending);
    list.insert(0, stored);
    return stored;
  }
}
