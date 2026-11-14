import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/resources/domain/resource.dart';
import 'package:focus_1/features/resources/presentation/providers/resource_providers.dart';

Resource _r(String id, ResourceType type, ResourceTopic topic) => Resource(
  id: id,
  type: type,
  topic: topic,
  title: id,
  meta: '',
  addedBy: '',
);

void main() {
  final all = [
    _r('v-char', ResourceType.video, ResourceTopic.characters),
    _r('v-text', ResourceType.video, ResourceTopic.texts),
    _r('q-char', ResourceType.quiz, ResourceTopic.characters),
  ];

  test('no filters returns everything', () {
    expect(filterResources(all), hasLength(3));
  });

  test('type and topic combine', () {
    final ids = filterResources(
      all,
      type: ResourceType.video,
      topic: ResourceTopic.characters,
    ).map((r) => r.id);
    expect(ids, ['v-char']);
  });

  test('an impossible combination is empty (drives the empty state)', () {
    expect(
      filterResources(all, type: ResourceType.quiz, topic: ResourceTopic.texts),
      isEmpty,
    );
  });

  test('every type routes to its viewer', () {
    expect(resourceRoute(all.first), '/resources/video/v-char');
    expect(resourceRoute(all.last), '/quiz/q-char');
  });
}
