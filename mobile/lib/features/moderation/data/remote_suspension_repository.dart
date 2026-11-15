import '../../../core/network/api_client.dart';
import '../domain/suspension.dart';
import 'suspension_repository.dart';

/// [SuspensionRepository] backed by the FCU API. Suspensions are set by the
/// FCU team; they end by themselves.
class RemoteSuspensionRepository implements SuspensionRepository {
  RemoteSuspensionRepository(this._api);

  final ApiClient _api;

  @override
  Future<Suspension?> getSuspension(String accountId) async {
    final json = objectOf(await _api.get('/me/suspension'));
    final s = objectOf(json?['suspension']);
    final until = DateTime.tryParse((s?['until'] as String?) ?? '');
    if (s == null || until == null) return null;
    return Suspension(
      reason: (s['reason'] as String?) ?? '',
      until: until.toLocal(),
    );
  }
}
