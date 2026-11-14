import '../../community/domain/person.dart';
import '../domain/post.dart';

abstract class PostRepository {
  Future<List<Post>> getPosts(String communityId, PostScope scope);
  Future<Post> toggleLike(Post post);
  Future<Post> createPost(Post post);
}

class FakePostRepository implements PostRepository {
  static const _latency = Duration(milliseconds: 400);

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

  @override
  Future<List<Post>> getPosts(String communityId, PostScope scope) async {
    await Future.delayed(_latency);
    return _byCommunity.putIfAbsent(
      communityId,
      () => scope == PostScope.general
          ? _seedGeneral(communityId)
          : _seedSpecific(communityId),
    );
  }

  @override
  Future<Post> toggleLike(Post post) async {
    await Future.delayed(_latency);
    final toggled = post.copyWith(
      likedByMe: !post.likedByMe,
      likeCount: post.likedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );
    final posts = _byCommunity[post.communityId];
    if (posts != null) {
      final index = posts.indexWhere((p) => p.id == post.id);
      if (index != -1) posts[index] = toggled;
    }
    return toggled;
  }

  @override
  Future<Post> createPost(Post post) async {
    await Future.delayed(_latency);
    final posts = _byCommunity.putIfAbsent(post.communityId, () => []);
    posts.insert(0, post);
    return post;
  }
}
