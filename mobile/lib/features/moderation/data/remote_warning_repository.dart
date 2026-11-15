import '../../../core/network/api_client.dart';
import '../domain/warning.dart';
import 'warning_repository.dart';

/// [WarningRepository] backed by the FCU API. Warnings are created on the
/// server when a moderator or the FCU team warns someone; the app only reads
/// and acknowledges its own.
class RemoteWarningRepository implements WarningRepository {
  RemoteWarningRepository(this._api, {required this._myId});

  final ApiClient _api;
  final String? Function() _myId;

  Warning _warning(Map<String, dynamic> j) => Warning(
    id: j['id'] as String,
    userId: _myId() ?? '',
    reason: (j['reason'] as String?) ?? '',
    preview: (j['preview'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((j['created_at'] as String?) ?? '')?.toLocal() ??
        DateTime.now(),
    acknowledged: j['acknowledged'] == true,
  );

  @override
  Future<Warning> create({
    required String userId,
    required String reason,
    required String preview,
  }) => throw UnsupportedError('Warnings are issued by the server');

  @override
  Future<List<Warning>> getWarningsFor(String userId) async {
    final items = await _api.getAllItems('/me/warnings');
    return items.map(_warning).toList();
  }

  @override
  Future<Warning> acknowledge(String id) async {
    final json = objectOf(await _api.post('/me/warnings/$id/acknowledge'));
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return _warning(json);
  }
}
