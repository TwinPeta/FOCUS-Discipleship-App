import '../../community/domain/person.dart';

/// One comment under a post (screen 39).
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.voteCount = 0,
    this.votedByMe = false,
  });

  final String id;
  final String postId;
  final Person author;
  final String text;
  final DateTime createdAt;

  /// "Helpful" votes on an answer to a question.
  final int voteCount;
  final bool votedByMe;

  Comment copyWith({
    String? id,
    String? postId,
    Person? author,
    String? text,
    DateTime? createdAt,
    int? voteCount,
    bool? votedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      author: author ?? this.author,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      voteCount: voteCount ?? this.voteCount,
      votedByMe: votedByMe ?? this.votedByMe,
    );
  }
}
