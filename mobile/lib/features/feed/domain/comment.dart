import '../../community/domain/person.dart';

/// A single reply on a [Post] (Screen 39).
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final Person author;
  final String body;
  final DateTime createdAt;

  Comment copyWith({
    String? id,
    String? postId,
    Person? author,
    String? body,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      author: author ?? this.author,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
