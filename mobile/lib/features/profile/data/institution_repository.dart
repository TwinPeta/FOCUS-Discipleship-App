import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';
import 'profile_api_mapper.dart';

/// The schools a student can pick when joining. The server owns the list: the
/// FOCUS team adds and removes institutions in the back office.
abstract class InstitutionRepository {
  Future<List<String>> names({
    required String country,
    required InstitutionType type,
  });
}

class RemoteInstitutionRepository implements InstitutionRepository {
  RemoteInstitutionRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<String>> names({
    required String country,
    required InstitutionType type,
  }) async {
    final items = await _api.getAllItems(
      '/lookups/institutions',
      query: {
        'type': institutionTypeToApi(type),
        'country': countryCodeOf(country),
      },
    );
    return [for (final i in items) i['name'] as String];
  }
}
