import 'package:focus_1/features/testimony/data/testimony_repository.dart';
import 'package:focus_1/features/testimony/domain/testimony.dart';

class FakeTestimonyRepository implements TestimonyRepository {
  FakeTestimonyRepository({
    this.latency = const Duration(milliseconds: 400),
    bool Function(String testimonyId)? isHidden,
    bool Function(String userId)? isBlocked,
  }) : _isHidden = isHidden ?? _never,
       _isBlocked = isBlocked ?? _never;

  /// Stories by people the user blocked are left out.
  final bool Function(String userId) _isBlocked;

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
        authorId: 'student-2',
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
        authorId: 'm-1',
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
            (t.authorId == null || !_isBlocked(t.authorId!)) &&
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

  bool _visible(Testimony t, String? viewerId) =>
      !_isHidden(t.id) &&
      (t.authorId == null || !_isBlocked(t.authorId!)) &&
      (t.status == TestimonyStatus.reviewed || t.isAuthoredBy(viewerId));

  (List<Testimony>, int)? _locate(String id) {
    for (final list in _byCommunity.values) {
      final i = list.indexWhere((t) => t.id == id);
      if (i != -1) return (list, i);
    }
    // A deep link can arrive before the community's seed is built.
    final cut = id.indexOf('-testimony-');
    if (cut > 0) {
      final communityId = id.substring(0, cut);
      final list = _byCommunity.putIfAbsent(
        communityId,
        () => _seed(communityId),
      );
      final i = list.indexWhere((t) => t.id == id);
      if (i != -1) return (list, i);
    }
    return null;
  }

  @override
  Future<Testimony?> getTestimony(
    String id, {
    required String? viewerId,
  }) async {
    await Future.delayed(latency);
    final found = _locate(id);
    if (found == null) return null;
    final t = found.$1[found.$2];
    return _visible(t, viewerId) ? t : null;
  }

  @override
  Future<Testimony> setEncouraged(String id, {required bool encouraged}) async {
    await Future.delayed(latency);
    final found = _locate(id);
    if (found == null) throw ArgumentError.value(id, 'id', 'unknown');
    final (list, i) = found;
    return list[i] = list[i].withEncouraged(encouraged);
  }
}
