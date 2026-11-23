import '../../../core/network/api_client.dart';
import '../../../core/network/media_uploader.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
import '../../community/domain/person.dart';
import '../../community/data/people_directory.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import 'post_api_mapper.dart';
import 'post_repository.dart';

/// [PostRepository] backed by the FCU API.
///
/// "Hide this post" is saved on the server for this member only (the feed
/// and search leave it out); it also takes effect at once in this session.
/// Posts by blocked people are filtered by the callers.
class RemotePostRepository implements PostRepository {
  RemotePostRepository(
    this._api,
    MediaUploader uploader,
    this._directory, {
    bool Function(String postId)? isHidden,
    Outbox? outbox,
  }) : _isHidden = isHidden ?? _never,
       _outbox = outbox ?? Outbox(api: _api, uploader: uploader);

  final ApiClient _api;
  final Outbox _outbox;
  final Map<String, Comment> _comments = {};
  final PeopleDirectory _directory;
  final bool Function(String postId) _isHidden;
  static bool _never(String _) => false;

  final Set<String> _hiddenForMe = {};
  final Map<String, PostScope> _scopes = {};
  final Map<String, Post> _seen = {};

  bool _visible(Post p) => !_hiddenForMe.contains(p.id) && !_isHidden(p.id);

  Post _remember(Post p) {
    _seen[p.id] = p;
    return p;
  }

  Future<PostScope> _scopeOf(String communityId) async {
    final known = _scopes[communityId];
    if (known != null) return known;
    final json = objectOf(await _api.get('/communities/$communityId'));
    final scope = json?['type'] == 'general'
        ? PostScope.general
        : PostScope.specific;
    return _scopes[communityId] = scope;
  }

  @override
  Future<PostPage> getPosts(
    String communityId,
    PostScope scope, {
    String? cursor,
    int limit = 20,
  }) async {
    _scopes[communityId] = scope;
    final json = objectOf(
      await _api.get(
        '/communities/$communityId/posts',
        query: {'limit': '$limit', 'cursor': ?cursor},
      ),
    );
    final posts = [
      for (final j in itemsOf(json))
        _remember(postFromApi(j, scope, remember: _directory)),
    ];
    return PostPage(
      items: posts.where(_visible).toList(),
      nextCursor: json?['next_cursor'] as String?,
    );
  }

  /// Saves [write]; while offline it waits in the outbox and [write]'s
  /// optimistic reply is returned.
  Future<Map<String, dynamic>?> _write(OfflineWrite write) async =>
      objectOf((await _outbox.write(write)).json);

  static String _stamp() => '${DateTime.now().microsecondsSinceEpoch}';

  /// Flips a `<flag>` / `<count>` pair on the saved copies of [id].
  static Object? Function(String, Object?) _toggle(
    String id,
    String flag,
    String? count,
    bool on,
  ) => (_, json) => patchEntity(json, id, (m) {
    if ((m[flag] == true) == on) return m;
    m[flag] = on;
    if (count != null) {
      final n = ((m[count] as int?) ?? 0) + (on ? 1 : -1);
      m[count] = n < 0 ? 0 : n;
    }
    return m;
  });

  static int? _guess(int? count, bool was, bool now) =>
      count == null || was == now ? count : count + (now ? 1 : -1);

  Map<String, dynamic> _authorJson(Person author) => {
    'id': author.id,
    'full_name': author.name,
    'community_role': switch (author.role) {
      PersonRole.superMentor => 'super_mentor',
      PersonRole.mentor => 'mentor',
      _ => 'member',
    },
  };

  @override
  Future<Post> setLiked(String postId, {required bool liked}) async {
    final known = _seen[postId];
    final json = await _write(
      OfflineWrite(
        method: liked ? 'PUT' : 'DELETE',
        endpoint: '/posts/$postId/like',
        entityType: 'post_like',
        clientId: 'like-$postId-${_stamp()}',
        coalesceKey: 'post_like:$postId',
        optimistic: {
          'like_count': ?_guess(known?.likeCount, known?.likedByMe ?? !liked, liked),
          'liked_by_me': liked,
        },
        patch: _toggle(postId, 'liked_by_me', 'like_count', liked),
      ),
    );
    final base = _seen[postId] ?? await getPost(postId);
    if (base == null) throw const ApiException(404, code: 'not_found');
    return _remember(
      base.copyWith(
        likeCount: (json?['like_count'] as int?) ?? base.likeCount,
        likedByMe: json?['liked_by_me'] == true,
      ),
    );
  }

  @override
  Future<Post> createPost(Post post) async {
    final paths = <String>[
      if (post.photo?.path != null) post.photo!.path!,
      ...post.media,
    ];
    final listPath = '/communities/${post.communityId}/posts';
    final optimistic = <String, dynamic>{
      'id': post.id,
      'community_id': post.communityId,
      if (!post.anonymous) 'author': _authorJson(post.author),
      'text': post.body,
      'created_at': apiNow(),
      'kind': post.kind == PostKind.question ? 'question' : 'post',
      'anonymous': post.anonymous,
      'is_mine': true,
      // Shown from the phone until it is sent.
      'media': [
        for (final path in paths) {'url': path, 'kind': 'image'},
      ],
      'pending': true,
    };
    final json = await _write(
      OfflineWrite(
        method: 'POST',
        endpoint: listPath,
        entityType: 'post',
        clientId: post.id,
        creates: true,
        body: {
          'text': post.body,
          if (post.kind == PostKind.question) 'kind': 'question',
          if (post.anonymous) 'anonymous': true,
        },
        media: [
          for (final path in paths)
            LocalMedia(path: path, purpose: 'post_photo'),
        ],
        optimistic: optimistic,
        patchWhere: firstPageOf(listPath),
        patch: (_, json) => insertItem(json, optimistic),
      ),
    );
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return _remember(postFromApi(json, post.scope, remember: _directory));
  }

  @override
  Future<Post?> getPost(String postId) async {
    try {
      final json = objectOf(await _api.get('/posts/$postId'));
      if (json == null) return null;
      final scope = await _scopeOf((json['community_id'] as String?) ?? '');
      final post = _remember(postFromApi(json, scope, remember: _directory));
      return _visible(post) ? post : null;
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    final items = await _api.getAllItems('/posts/$postId/comments');
    return [
      for (final j in items)
        _comments[j['id'] as String] = commentFromApi(
          j,
          postId,
          remember: _directory,
        ),
    ];
  }

  @override
  Future<Comment> addComment(Comment comment) async {
    final listPath = '/posts/${comment.postId}/comments';
    final optimistic = <String, dynamic>{
      'id': comment.id,
      'post_id': comment.postId,
      'author': _authorJson(comment.author),
      'text': comment.text,
      'created_at': apiNow(),
      'pending': true,
    };
    final json = await _write(
      OfflineWrite(
        method: 'POST',
        endpoint: listPath,
        entityType: 'comment',
        clientId: comment.id,
        creates: true,
        body: {'text': comment.text},
        optimistic: optimistic,
        patch: (key, json) => cachedPathOf(key) == listPath
            ? insertItem(json, optimistic, atEnd: true)
            : patchEntity(json, comment.postId, (m) {
                m['comment_count'] = ((m['comment_count'] as int?) ?? 0) + 1;
                return m;
              }),
      ),
    );
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return commentFromApi(json, comment.postId, remember: _directory);
  }

  Future<void> _setHidden(String postId, bool hidden) => _write(
    OfflineWrite(
      method: hidden ? 'PUT' : 'DELETE',
      endpoint: '/posts/$postId/hide',
      entityType: 'post_hide',
      clientId: 'hide-$postId-${_stamp()}',
      coalesceKey: 'post_hide:$postId',
      patch: hidden ? (_, json) => removeEntity(json, postId) : null,
    ),
  );

  @override
  Future<void> hidePost(String postId) async {
    await _setHidden(postId, true);
    _hiddenForMe.add(postId);
  }

  @override
  Future<void> unhidePost(String postId) async {
    await _setHidden(postId, false);
    _hiddenForMe.remove(postId);
  }

  @override
  Future<void> setPassed(String postId, {required bool passed}) async {
    await _write(
      OfflineWrite(
        method: passed ? 'PUT' : 'DELETE',
        endpoint: '/posts/$postId/pass',
        entityType: 'post_pass',
        clientId: 'pass-$postId-${_stamp()}',
        coalesceKey: 'post_pass:$postId',
        patch: _toggle(postId, 'passed_by_me', null, passed),
      ),
    );
    final seen = _seen[postId];
    if (seen != null) _remember(seen.copyWith(passedByMe: passed));
  }

  @override
  Future<void> deletePost(String postId, {required String byUserId}) async {
    try {
      await _api.delete('/posts/$postId');
      _seen.remove(postId);
    } on ApiException catch (e) {
      if (e.status == 403) throw const PostPermissionDenied();
      rethrow;
    }
  }

  @override
  Future<Post> setFollowing(String postId, {required bool following}) async {
    final known = _seen[postId];
    final json = await _write(
      OfflineWrite(
        method: following ? 'PUT' : 'DELETE',
        endpoint: '/posts/$postId/follow',
        entityType: 'post_follow',
        clientId: 'follow-$postId-${_stamp()}',
        coalesceKey: 'post_follow:$postId',
        optimistic: {
          'following': following,
          'follower_count': ?_guess(
            known?.followerCount,
            known?.following ?? !following,
            following,
          ),
        },
        patch: _toggle(postId, 'following', 'follower_count', following),
      ),
    );
    final base = _seen[postId] ?? await getPost(postId);
    if (base == null) throw const ApiException(404, code: 'not_found');
    return _remember(
      base.copyWith(
        following: json?['following'] == true,
        followerCount: (json?['follower_count'] as int?) ?? base.followerCount,
      ),
    );
  }

  @override
  Future<({int count, bool mine})> setVoted(
    String commentId, {
    required bool voted,
  }) async {
    try {
      final known = _comments[commentId];
      final json = await _write(
        OfflineWrite(
          method: voted ? 'PUT' : 'DELETE',
          endpoint: '/comments/$commentId/vote',
          entityType: 'comment_vote',
          clientId: 'vote-$commentId-${_stamp()}',
          coalesceKey: 'comment_vote:$commentId',
          optimistic: {
            'voted_by_me': voted,
            'vote_count': ?_guess(
              known?.voteCount,
              known?.votedByMe ?? !voted,
              voted,
            ),
          },
          patch: _toggle(commentId, 'voted_by_me', 'vote_count', voted),
        ),
      );
      return (
        count: (json?['vote_count'] as int?) ?? 0,
        mine: json?['voted_by_me'] == true,
      );
    } on ApiException catch (e) {
      if (e.status == 403) throw const OwnAnswerVote();
      rethrow;
    }
  }

  @override
  Future<List<Post>> searchPosts(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final json = objectOf(
      await _api.get('/search/posts', query: {'q': q, 'limit': '30'}),
    );
    final items = (json?['items'] as List?) ?? const [];
    return [
      for (final j in items.whereType<Map<String, dynamic>>())
        if (!_hiddenForMe.contains(j['id']))
          _remember(
            postFromApi(
              j,
              await _scopeOf((j['community_id'] as String?) ?? ''),
              remember: _directory,
            ),
          ),
    ];
  }
}
