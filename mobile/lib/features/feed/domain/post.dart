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
  const PostPhoto.file(String this.path) : isArt = false;
  const PostPhoto.art() : path = null, isArt = true;

  final String? path;
  final bool isArt;
}

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
    );
  }
}
