import '../../../core/network/api_client.dart';
import '../domain/resource.dart';
import 'resource_repository.dart';

/// [ResourceRepository] backed by the FCU API.
class RemoteResourceRepository implements ResourceRepository {
  RemoteResourceRepository(this._api);

  final ApiClient _api;

  static ResourceType _type(String? t) {
    switch (t) {
      case 'video':
        return ResourceType.video;
      case 'quiz':
        return ResourceType.quiz;
      case 'document':
        return ResourceType.document;
      default:
        return ResourceType.devotional;
    }
  }

  static ResourceTopic _topic(String? c) {
    switch (c) {
      case 'bible_characters':
        return ResourceTopic.characters;
      case 'bible_texts':
        return ResourceTopic.texts;
      default:
        return ResourceTopic.none;
    }
  }

  static String _minutes(int? seconds) =>
      seconds == null ? '' : '${(seconds / 60).ceil()} min';

  @override
  Future<List<Resource>> getResources(String communityId) async {
    final items = await _api.getAllItems('/communities/$communityId/resources');
    return [
      for (final j in items)
        () {
          final type = _type(j['type'] as String?);
          final by = objectOf(j['added_by']);
          final name = (by?['full_name'] as String?) ?? 'FCU team';
          final lead = switch (type) {
            ResourceType.video => _minutes(j['duration_seconds'] as int?),
            ResourceType.devotional => '${j['read_minutes'] ?? 5} min read',
            ResourceType.quiz => '${j['question_count'] ?? ''} questions',
            ResourceType.document => 'PDF',
          };
          return Resource(
            id: j['id'] as String,
            type: type,
            topic: _topic(j['category'] as String?),
            title: (j['title'] as String?) ?? '',
            meta: '$lead · Added by $name',
            addedBy: name,
          );
        }(),
    ];
  }
}
