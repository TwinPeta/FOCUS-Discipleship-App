import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/resource.dart';

final resourcesProvider = FutureProvider.family<List<Resource>, String>((
  ref,
  communityId,
) {
  return ref.watch(resourceRepositoryProvider).getResources(communityId);
});
