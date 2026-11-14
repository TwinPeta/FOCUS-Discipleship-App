import '../../community/domain/person.dart';
import '../domain/post.dart';

abstract class PostRepository {
  /// Newest first. Pass the previous page's `nextCursor` to continue.
  Future<PostPage> getPosts(
    String communityId,
    PostScope scope, {
    String? cursor,
    int limit = 20,
  });

  /// Idempotent: sets the current user's like to [liked] and returns the
  /// stored post (calling it twice with the same value changes nothing).
  Future<Post> setLiked(String postId, {required bool liked});

  /// Idempotent on the post id: a repeated create returns the stored post.
  Future<Post> createPost(Post post);
}

class FakePostRepository implements PostRepository {
  FakePostRepository({
    this.latency = const Duration(milliseconds: 400),
    bool Function(String postId)? isHidden,
  }) : _isHidden = isHidden ?? _never;

  final Duration latency;

  /// Content hidden by moderation never leaves the repository.
  final bool Function(String postId) _isHidden;
  static bool _never(String _) => false;

  final Map<String, List<Post>> _byCommunity = {};

  List<Post> _seedSpecific(String communityId) {
    final now = DateTime.now();
    return [
      Post(
        id: '$communityId-post-1',
        communityId: communityId,
        scope: PostScope.specific,
        author: const Person(
          id: 'sm-1',
          name: 'Grace Namuli',
          role: PersonRole.superMentor,
        ),
        roleLabel: 'Super-mentor',
        body:
            "Reminder: we're meeting in Room 204 this week instead of the chapel, "
            "since the chapel is booked for choir practice. See you all at 5!",
        createdAt: now.subtract(const Duration(hours: 2)),
        likeCount: 9,
      ),
      Post(
        id: '$communityId-post-photo',
        communityId: communityId,
        scope: PostScope.specific,
        author: const Person(
          id: 'm-1',
          name: 'David Okello',
          role: PersonRole.mentor,
        ),
        roleLabel: 'Mentor',
        body:
            'Sunrise prayer walk this morning before lectures. Join us next '
            'Saturday at 6:30, we meet at the main gate.',
        createdAt: now.subtract(const Duration(hours: 6)),
        photo: const PostPhoto.art(),
        likeCount: 12,
      ),
      Post(
        id: '$communityId-post-2',
        communityId: communityId,
        scope: PostScope.specific,
        author: const Person(
          id: 'm-1',
          name: 'David Okello',
          role: PersonRole.mentor,
        ),
        roleLabel: 'Mentor',
        body:
            'Proud of how everyone showed up for each other during exam week. '
            "Keep leaning on one another, that's what this community is for.",
        createdAt: now.subtract(const Duration(days: 1)),
        likeCount: 14,
      ),
      Post(
        id: '$communityId-post-3',
        communityId: communityId,
        scope: PostScope.specific,
        author: const Person(
          id: 'member-1',
          name: 'Faith Nabirye',
          role: PersonRole.member,
        ),
        body:
            'Please keep my family in your prayers this week, my dad is not feeling '
            'well. Thank you all for the encouragement last week, it meant a lot.',
        createdAt: now.subtract(const Duration(days: 2)),
        likeCount: 6,
      ),
    ];
  }

  List<Post> _seedGeneral(String communityId) {
    final now = DateTime.now();
    return [
      Post(
        id: '$communityId-post-1',
        communityId: communityId,
        scope: PostScope.general,
        author: const Person(
          id: 'campus-team-1',
          name: 'FCU Campus Team',
          role: PersonRole.superMentor,
        ),
        roleLabel: 'Campus team',
        body:
            'Welcome to a new semester! Keep an eye here for campus-wide events, '
            'and remember every specific community meets in person every week.',
        createdAt: now.subtract(const Duration(hours: 5)),
        likeCount: 21,
      ),
      Post(
        id: '$communityId-post-2',
        communityId: communityId,
        scope: PostScope.general,
        author: const Person(
          id: 'student-1',
          name: 'Joseph Mwangi',
          role: PersonRole.member,
        ),
        roleLabel: 'Student',
        body:
            'Anyone else heading to the Friday worship night? Looking for a group '
            'to walk over with from the main gate.',
        createdAt: now.subtract(const Duration(hours: 9)),
        likeCount: 5,
      ),
      Post(
        id: '$communityId-post-3',
        communityId: communityId,
        scope: PostScope.general,
        author: const Person(
          id: 'student-2',
          name: 'Patience Achieng',
          role: PersonRole.member,
        ),
        body:
            'Grateful for how my small group prayed with me through a hard week. '
            "If you're new, don't be afraid to ask for a specific community.",
        createdAt: now.subtract(const Duration(days: 1)),
        likeCount: 3,
      ),
    ];
  }

  List<Post> _feed(String communityId, PostScope scope) =>
      _byCommunity.putIfAbsent(
        communityId,
        () => scope == PostScope.general
            ? _seedGeneral(communityId)
            : _seedSpecific(communityId),
      );

  @override
  Future<PostPage> getPosts(
    String communityId,
    PostScope scope, {
    String? cursor,
    int limit = 20,
  }) async {
    await Future.delayed(latency);
    final all = _feed(
      communityId,
      scope,
    ).where((p) => !_isHidden(p.id)).toList();
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + limit).clamp(0, all.length);
    return PostPage(
      // A copy: callers never share (or mutate) the stored list.
      items: List.unmodifiable(all.sublist(start.clamp(0, all.length), end)),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  @override
  Future<Post> setLiked(String postId, {required bool liked}) async {
    await Future.delayed(latency);
    for (final posts in _byCommunity.values) {
      final index = posts.indexWhere((p) => p.id == postId);
      if (index == -1) continue;
      final current = posts[index];
      if (current.likedByMe == liked) return current;
      final updated = current.copyWith(
        likedByMe: liked,
        likeCount: current.likeCount + (liked ? 1 : -1),
      );
      posts[index] = updated;
      return updated;
    }
    throw ArgumentError('Unknown post id: $postId');
  }

  @override
  Future<Post> createPost(Post post) async {
    await Future.delayed(latency);
    final posts = _feed(post.communityId, post.scope);
    final existing = posts.where((p) => p.id == post.id).firstOrNull;
    if (existing != null) return existing;
    posts.insert(0, post);
    return post;
  }
}
