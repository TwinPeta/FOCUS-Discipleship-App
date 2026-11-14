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

  /// Returns the post with [postId], or null when not found.
  Future<Post?> getPostById(String postId);

  /// Idempotent: sets the current user's like to [liked] and returns the
  /// stored post (calling it twice with the same value changes nothing).
  Future<Post> setLiked(String postId, {required bool liked});

  /// Idempotent on the post id: a repeated create returns the stored post.
  Future<Post> createPost(Post post);

  /// Chronological (oldest first) comments for [postId].
  Future<List<Comment>> getComments(String postId);

  /// Idempotent on [comment.id]: a repeated submit returns the stored comment.
  Future<Comment> addComment(String postId, Comment comment);
}

class FakePostRepository implements PostRepository {
  FakePostRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  final Map<String, List<Post>> _byCommunity = {};
  final Map<String, List<Comment>> _commentsByPost = {};

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

  List<Comment> _seedComments(String postId) {
    if (!postId.endsWith('-post-1') && !postId.endsWith('-post-photo')) {
      return [];
    }
    final now = DateTime.now();
    if (postId.endsWith('-post-photo')) {
      return [
        Comment(
          id: '$postId-c1',
          postId: postId,
          author: const Person(
            id: 'sm-1',
            name: 'Grace Namuli',
            role: PersonRole.superMentor,
          ),
          body: 'Loved praying together before class — count me in next Saturday!',
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
      ];
    }
    return [
      Comment(
        id: '$postId-c1',
        postId: postId,
        author: const Person(
          id: 'm-1',
          name: 'David Okello',
          role: PersonRole.mentor,
        ),
        body: 'Thanks for the heads-up! Bringing extra notebooks for the study.',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      Comment(
        id: '$postId-c2',
        postId: postId,
        author: const Person(
          id: 'member-1',
          name: 'Faith Nabirye',
          role: PersonRole.member,
        ),
        body: 'See everyone at 5 in Room 204!',
        createdAt: now.subtract(const Duration(minutes: 45)),
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

  List<Comment> _commentsFor(String postId) =>
      _commentsByPost.putIfAbsent(postId, () => _seedComments(postId));

  /// Ensures a seeded community feed is initialized when deep-linking directly
  /// to a post ID before the feed list has been opened.
  void _ensureSeededForPostId(String postId) {
    final marker = postId.indexOf('-post-');
    if (marker <= 0) return;
    final communityId = postId.substring(0, marker);
    if (_byCommunity.containsKey(communityId)) return;
    final scope = communityId.startsWith('general-')
        ? PostScope.general
        : PostScope.specific;
    _feed(communityId, scope);
  }

  (List<Post>, int)? _findPost(String postId) {
    for (final posts in _byCommunity.values) {
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) return (posts, index);
    }
    _ensureSeededForPostId(postId);
    for (final posts in _byCommunity.values) {
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) return (posts, index);
    }
    return null;
  }

  @override
  Future<PostPage> getPosts(
    String communityId,
    PostScope scope, {
    String? cursor,
    int limit = 20,
  }) async {
    await Future.delayed(latency);
    final all = _feed(communityId, scope);
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + limit).clamp(0, all.length);
    return PostPage(
      // A copy: callers never share (or mutate) the stored list.
      items: List.unmodifiable(all.sublist(start.clamp(0, all.length), end)),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  @override
  Future<Post?> getPostById(String postId) async {
    await Future.delayed(latency);
    final found = _findPost(postId);
    if (found == null) return null;
    final (posts, index) = found;
    return posts[index];
  }

  @override
  Future<Post> setLiked(String postId, {required bool liked}) async {
    await Future.delayed(latency);
    final found = _findPost(postId);
    if (found == null) throw ArgumentError('Unknown post id: $postId');
    final (posts, index) = found;
    final current = posts[index];
    if (current.likedByMe == liked) return current;
    final updated = current.copyWith(
      likedByMe: liked,
      likeCount: current.likeCount + (liked ? 1 : -1),
    );
    posts[index] = updated;
    return updated;
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

  @override
  Future<List<Comment>> getComments(String postId) async {
    await Future.delayed(latency);
    final comments = _commentsFor(postId);
    return List.unmodifiable(comments);
  }

  @override
  Future<Comment> addComment(String postId, Comment comment) async {
    await Future.delayed(latency);
    final comments = _commentsFor(postId);
    final existing = comments.where((c) => c.id == comment.id).firstOrNull;
    if (existing != null) return existing;
    comments.add(comment);
    return comment;
  }
}
