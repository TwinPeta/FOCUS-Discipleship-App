import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../learning/domain/learning_models.dart';
import '../../../learning/presentation/learning_providers.dart';
import '../../domain/resource.dart';

final resourcesProvider = FutureProvider.family<List<Resource>, String>((
  ref,
  communityId,
) {
  return ref.watch(resourceRepositoryProvider).getResources(communityId);
});

/// Type and topic filters combine (AND); a null filter matches everything.
List<Resource> filterResources(
  List<Resource> resources, {
  ResourceType? type,
  ResourceTopic? topic,
}) => resources
    .where((r) => type == null || r.type == type)
    .where((r) => topic == null || r.topic == topic)
    .toList();

/// The route of each resource's viewer. [communityId] lets the viewer
/// return to this community's Resources tab.
String resourceRoute(Resource r, {String? communityId}) => learningRoute(
  switch (r.type) {
    ResourceType.video => LearningKind.video,
    ResourceType.devotional => LearningKind.devotional,
    ResourceType.quiz => LearningKind.quiz,
    ResourceType.document => LearningKind.document,
  },
  r.id,
  communityId: communityId,
);
