import '../../community/domain/person.dart';
import '../domain/comment.dart';
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

  /// The stored post, or null if it does not exist (or was deleted).
  Future<Post?> getPost(String postId);

  /// Oldest first.
  Future<List<Comment>> getComments(String postId);

  /// Idempotent on the comment id. Raises the post's comment count.
  Future<Comment> addComment(Comment comment);

  /// Hides a post for the current user only ("Hide this post"). Hidden
  /// posts are left out of [getPosts] and [getPost]. Idempotent.
  Future<void> hidePost(String postId);

  /// Undoes [hidePost]. Idempotent.
  Future<void> unhidePost(String postId);

  /// Deletes a post. Only its author may: throws [PostPermissionDenied]
  /// for anyone else.
  Future<void> deletePost(String postId, {required String byUserId});
}

class PostPermissionDenied implements Exception {
  const PostPermissionDenied();
  @override
  String toString() => 'Only the author can delete this post.';
}

class FakePostRepository implements PostRepository {
  FakePostRepository({
    this.latency = const Duration(milliseconds: 400),
    bool Function(String postId)? isHidden,
    bool Function(String userId)? isBlocked,
  }) : _isHidden = isHidden ?? _never,
       _isBlocked = isBlocked ?? _never;

  final Duration latency;

  /// Content hidden by moderation never leaves the repository.
  final bool Function(String postId) _isHidden;

  /// Posts and comments by people the user blocked never leave it either.
  final bool Function(String userId) _isBlocked;
  static bool _never(String _) => false;

  bool _visible(Post p) =>
      !_hiddenForMe.contains(p.id) &&
      !_isHidden(p.id) &&
      !_isBlocked(p.author.id);

  final Map<String, List<Post>> _byCommunity = {};
  final Map<String, List<Comment>> _comments = {};
  final Set<String> _hiddenForMe = {};

  /// Seeded posts ending in `-post-1` or `-post-photo` start with two
  /// comments each; every other post starts with none.
  List<Comment> _commentsFor(String postId) =>
      _comments.putIfAbsent(postId, () {
        if (!postId.endsWith('-post-1') && !postId.endsWith('-post-photo')) {
          return <Comment>[];
        }
        final now = DateTime.now();
        return [
          Comment(
            id: '$postId-comment-1',
            postId: postId,
            author: const Person(
              id: 'member-2',
              name: 'Peter Ssentongo',
              role: PersonRole.member,
            ),
            text: 'Thanks for letting us know, see you there!',
            createdAt: now.subtract(const Duration(minutes: 90)),
          ),
          Comment(
            id: '$postId-comment-2',
            postId: postId,
            author: const Person(
              id: 'member-3',
              name: 'Joy Atim',
              role: PersonRole.member,
            ),
            text: 'Will there be snacks again? Asking for a friend.',
            createdAt: now.subtract(const Duration(minutes: 40)),
          ),
        ];
      });

  Post _withCount(Post post) =>
      post.copyWith(commentCount: _commentsFor(post.id).length);

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
    final all = _feed(communityId, scope).where(_visible).toList();
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + limit).clamp(0, all.length);
    return PostPage(
      // A copy: callers never share (or mutate) the stored list.
      items: List.unmodifiable(
        all.sublist(start.clamp(0, all.length), end).map(_withCount),
      ),
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
      if (current.likedByMe == liked) return _withCount(current);
      final updated = current.copyWith(
        likedByMe: liked,
        likeCount: current.likeCount + (liked ? 1 : -1),
      );
      posts[index] = updated;
      return _withCount(updated);
    }
    throw ArgumentError('Unknown post id: $postId');
  }

  @override
  Future<Post> createPost(Post post) async {
    await Future.delayed(latency);
    final posts = _feed(post.communityId, post.scope);
    final existing = posts.where((p) => p.id == post.id).firstOrNull;
    if (existing != null) return _withCount(existing);
    posts.insert(0, post);
    return _withCount(post);
  }

  @override
  Future<Post?> getPost(String postId) async {
    await Future.delayed(latency);
    for (final posts in _byCommunity.values) {
      final post = posts.where((p) => p.id == postId).firstOrNull;
      if (post != null) return _visible(post) ? _withCount(post) : null;
    }
    return null;
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    await Future.delayed(latency);
    return List.unmodifiable(
      _commentsFor(postId)
          .where((c) => !_isHidden(c.id) && !_isBlocked(c.author.id)),
    );
  }

  @override
  Future<Comment> addComment(Comment comment) async {
    await Future.delayed(latency);
    final comments = _commentsFor(comment.postId);
    final existing = comments.where((c) => c.id == comment.id).firstOrNull;
    if (existing != null) return existing;
    comments.add(comment);
    return comment;
  }

  @override
  Future<void> hidePost(String postId) async {
    await Future.delayed(latency);
    _hiddenForMe.add(postId);
  }

  @override
  Future<void> unhidePost(String postId) async {
    await Future.delayed(latency);
    _hiddenForMe.remove(postId);
  }

  @override
  Future<void> deletePost(String postId, {required String byUserId}) async {
    await Future.delayed(latency);
    for (final posts in _byCommunity.values) {
      final post = posts.where((p) => p.id == postId).firstOrNull;
      if (post == null) continue;
      if (post.author.id != byUserId) throw const PostPermissionDenied();
      posts.remove(post);
      _comments.remove(postId);
      return;
    }
  }
}
