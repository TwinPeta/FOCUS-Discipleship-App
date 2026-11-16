import '../../../core/network/api_client.dart';
import '../../../core/network/media_uploader.dart';
import '../../community/data/people_directory.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import 'post_api_mapper.dart';
import 'post_repository.dart';

/// [PostRepository] backed by the FCU API.
///
/// "Hide this post" is kept on the device only (the API has no per-user
/// hide), so hidden posts come back after a restart. Posts by blocked
/// people are filtered by the callers.
class RemotePostRepository implements PostRepository {
  RemotePostRepository(
    this._api,
    this._uploader,
    this._directory, {
    bool Function(String postId)? isHidden,
  }) : _isHidden = isHidden ?? _never;

  final ApiClient _api;
  final MediaUploader _uploader;
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

  @override
  Future<Post> setLiked(String postId, {required bool liked}) async {
    final json = objectOf(
      liked
          ? await _api.put('/posts/$postId/like')
          : await _api.delete('/posts/$postId/like'),
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
    final mediaIds = <String>[];
    for (final path in paths) {
      mediaIds.add(await _uploader.uploadPhoto(path, purpose: 'post_photo'));
    }
    final json = objectOf(
      await _api.post(
        '/communities/${post.communityId}/posts',
        headers: {'Idempotency-Key': post.id},
        body: {
          'text': post.body,
          if (mediaIds.isNotEmpty) 'media_ids': mediaIds,
          if (post.kind == PostKind.question) 'kind': 'question',
          if (post.anonymous) 'anonymous': true,
        },
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
      for (final j in items) commentFromApi(j, postId, remember: _directory),
    ];
  }

  @override
  Future<Comment> addComment(Comment comment) async {
    final json = objectOf(
      await _api.post(
        '/posts/${comment.postId}/comments',
        body: {'text': comment.text},
      ),
    );
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return commentFromApi(json, comment.postId, remember: _directory);
  }

  @override
  Future<void> hidePost(String postId) async => _hiddenForMe.add(postId);

  @override
  Future<void> unhidePost(String postId) async => _hiddenForMe.remove(postId);

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
}
