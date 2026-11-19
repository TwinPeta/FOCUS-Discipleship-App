import 'package:focus_1/features/resources/data/resource_repository.dart';
import 'package:focus_1/features/resources/domain/resource.dart';

class FakeResourceRepository implements ResourceRepository {
  static const _latency = Duration(milliseconds: 400);

  @override
  Future<List<Resource>> getResources(String communityId) async {
    await Future.delayed(_latency);
    return seed;
  }

  /// Seeded resources, also used by the learning content catalogue.
  static const seed = <Resource>[
    Resource(
      id: 'resource-1',
      type: ResourceType.video,
      topic: ResourceTopic.characters,
      title: 'The faith of Abraham',
      meta: '8 min · Added by Grace Namuli',
      addedBy: 'Grace Namuli',
    ),
    Resource(
      id: 'resource-2',
      type: ResourceType.devotional,
      topic: ResourceTopic.texts,
      title: 'Walking by the Spirit — Galatians 5',
      meta: '5 min read · Added by David Okello',
      addedBy: 'David Okello',
    ),
    Resource(
      id: 'resource-3',
      type: ResourceType.quiz,
      topic: ResourceTopic.characters,
      title: 'Quiz: Kings of Israel',
      meta: '10 questions · Added by Esther Uwase',
      addedBy: 'Esther Uwase',
    ),
    Resource(
      id: 'resource-4',
      type: ResourceType.document,
      topic: ResourceTopic.none,
      title: 'Small group discussion guide',
      meta: 'PDF · Added by Samuel Kato',
      addedBy: 'Samuel Kato',
    ),
    Resource(
      id: 'resource-5',
      type: ResourceType.video,
      topic: ResourceTopic.texts,
      title: 'Understanding the book of Romans',
      meta: '14 min · Added by Brian Mugisha',
      addedBy: 'Brian Mugisha',
    ),
  ];
}
