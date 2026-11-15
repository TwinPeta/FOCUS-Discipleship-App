import '../domain/resource.dart';

abstract class ResourceRepository {
  Future<List<Resource>> getResources(String communityId);
}
