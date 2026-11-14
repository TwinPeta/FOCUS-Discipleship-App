import '../domain/testimony.dart';

abstract class TestimonyRepository {
  /// Reviewed stories are visible to everyone; a pending story is visible
  /// only to its own author.
  Future<List<Testimony>> getTestimonies(String communityId);
  Future<Testimony> submitStory(Testimony testimony);
}

class FakeTestimonyRepository implements TestimonyRepository {
  static const _latency = Duration(milliseconds: 400);

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
  Future<List<Testimony>> getTestimonies(String communityId) async {
    await Future.delayed(_latency);
    final all = _byCommunity.putIfAbsent(communityId, () => _seed(communityId));
    return all
        .where((t) => t.status == TestimonyStatus.reviewed || t.isMine)
        .toList();
  }

  @override
  Future<Testimony> submitStory(Testimony testimony) async {
    await Future.delayed(_latency);
    final list = _byCommunity.putIfAbsent(testimony.communityId, () => []);
    list.insert(0, testimony);
    return testimony;
  }
}
