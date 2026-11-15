import '../domain/community.dart';
import '../domain/person.dart';

abstract class CommunityRepository {
  Future<Community> getGeneralCommunity(
    String institutionId,
    String institutionName,
  );
  Future<List<Community>> getSpecificCommunities(String institutionId);
  Future<Community> getCommunityById(String id);
  Future<List<Person>> getMembers(String communityId);
}
