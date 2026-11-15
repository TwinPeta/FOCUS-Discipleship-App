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
