import '../../community/domain/person.dart';

enum PostScope { general, specific }

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
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}
