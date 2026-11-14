import '../../community/domain/person.dart';

/// One comment under a post (screen 39).
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final Person author;
  final String text;
  final DateTime createdAt;

  Comment copyWith({
    String? id,
    String? postId,
    Person? author,
    String? text,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      author: author ?? this.author,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
