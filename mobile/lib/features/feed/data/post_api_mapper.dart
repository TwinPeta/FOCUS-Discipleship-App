import '../../../core/network/api_client.dart';
import '../../community/data/community_api_mapper.dart';
import '../../community/data/people_directory.dart';
import '../../community/domain/person.dart';
import '../domain/comment.dart';
import '../domain/post.dart';

/// "Super-mentor" / "Mentor" / "Student" badge for a post's author.
String roleLabelFor(Person p) =>
    p.role == PersonRole.member ? 'Student' : p.role.label;

Person authorFrom(Object? userRef, PeopleDirectory? remember) {
  final map = objectOf(userRef) ?? const <String, dynamic>{'id': ''};
  if (remember != null && map['id'] != '') {
    memberFromApi(map, remember: remember);
  }
  return personFromApi(map);
}

/// API `Post` -> [Post]. The first image becomes the post's photo; any other
/// attachment URLs go in `media`.
Post postFromApi(
  Map<String, dynamic> j,
  PostScope scope, {
  PeopleDirectory? remember,
}) {
  final author = authorFrom(j['author'], remember);
  final urls = <String>[];
  final media = j['media'];
  if (media is List) {
    for (final m in media.whereType<Map<String, dynamic>>()) {
      final url = m['url'] as String?;
      if (url != null) urls.add(url);
    }
  }
  return Post(
    id: j['id'] as String,
    communityId: (j['community_id'] as String?) ?? '',
    scope: scope,
    author: author,
    body: (j['text'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((j['created_at'] as String?) ?? '') ?? DateTime.now(),
    roleLabel: roleLabelFor(author),
    photo: urls.isEmpty ? null : PostPhoto.network(urls.first),
    media: urls.length > 1 ? urls.sublist(1) : const [],
    likeCount: (j['like_count'] as int?) ?? 0,
    likedByMe: j['liked_by_me'] == true,
    commentCount: (j['comment_count'] as int?) ?? 0,
  );
}

Comment commentFromApi(
  Map<String, dynamic> j,
  String postId, {
  PeopleDirectory? remember,
}) => Comment(
  id: j['id'] as String,
  postId: postId,
  author: authorFrom(j['author'], remember),
  text: (j['text'] as String?) ?? '',
  createdAt:
      DateTime.tryParse((j['created_at'] as String?) ?? '') ?? DateTime.now(),
);
