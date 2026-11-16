import '../../community/domain/person.dart';

enum PostScope { general, specific }

/// Identifies one feed: the scope is explicit so the General feed never has
/// to look its community up in the specific-community catalogue.
typedef FeedKey = ({String communityId, PostScope scope});

/// One page of posts, newest first. [nextCursor] is null on the last page.
class PostPage {
  const PostPage({required this.items, this.nextCursor});

  final List<Post> items;
  final String? nextCursor;
}

/// The single photo shown above a post's caption: a picked file, or (for
/// seeded posts) vector placeholder art.
class PostPhoto {
  const PostPhoto.file(String this.path) : url = null, isArt = false;
  const PostPhoto.network(String this.url) : path = null, isArt = false;
  const PostPhoto.art() : path = null, url = null, isArt = true;

  final String? path;

  /// A photo already uploaded to the backend.
  final String? url;
  final bool isArt;
}

/// A post, or a question the community answers in the comments.
enum PostKind { post, question }

class Post {
  const Post({
    required this.id,
    required this.communityId,
    required this.scope,
    required this.author,
    required this.body,
    required this.createdAt,
    this.roleLabel,
    this.media = const [],
    this.photo,
    this.likeCount = 0,
    this.likedByMe = false,
    this.commentCount = 0,
    this.kind = PostKind.post,
    this.anonymous = false,
    this.isMine = false,
  });

  final String id;
  final String communityId;
  final PostScope scope;
  final Person author;
  final String body;
  final DateTime createdAt;

  /// Display label for the role badge (e.g. "Super-mentor", "Campus team").
  /// Posts with no label also show no action row.
  final String? roleLabel;
  final List<String> media;
  final PostPhoto? photo;
  final int likeCount;
  final bool likedByMe;
  final int commentCount;
  final PostKind kind;

  /// Shown as "Anonymous" to everyone (moderators can still see who).
  final bool anonymous;

  /// Written by the signed-in student (also when anonymous).
  final bool isMine;

  /// The name to show: "Anonymous" for anonymous posts.
  String get displayName => anonymous ? 'Anonymous' : author.name;
  String get displayInitials => anonymous ? '?' : author.initials;

  Post copyWith({
    String? id,
    String? communityId,
    PostScope? scope,
    Person? author,
    String? body,
    DateTime? createdAt,
    String? roleLabel,
    List<String>? media,
    PostPhoto? photo,
    int? likeCount,
    bool? likedByMe,
    int? commentCount,
    PostKind? kind,
    bool? anonymous,
    bool? isMine,
  }) {
    return Post(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      scope: scope ?? this.scope,
      author: author ?? this.author,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      roleLabel: roleLabel ?? this.roleLabel,
      media: media ?? this.media,
      photo: photo ?? this.photo,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      commentCount: commentCount ?? this.commentCount,
      kind: kind ?? this.kind,
      anonymous: anonymous ?? this.anonymous,
      isMine: isMine ?? this.isMine,
    );
  }
}
