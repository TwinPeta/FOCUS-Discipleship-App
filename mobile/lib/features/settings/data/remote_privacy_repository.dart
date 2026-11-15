import '../../../core/network/api_client.dart';
import 'privacy_repository.dart';

/// [PrivacyRepository] backed by the FCU API: the export is queued on the
/// server and the download link is sent to the account's email.
class RemotePrivacyRepository implements PrivacyRepository {
  RemotePrivacyRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> requestDataExport(String accountId) async {
    await _api.post('/me/export');
  }
}
