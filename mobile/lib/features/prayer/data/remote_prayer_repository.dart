import '../../../core/network/api_client.dart';
import '../../community/data/people_directory.dart';
import '../domain/prayer_request.dart';
import '../domain/prayer_response.dart';
import 'prayer_repository.dart';
import '../../community/data/community_api_mapper.dart';

/// [PrayerRepository] backed by the FCU API. The server keeps anonymous
/// authors out of every reply; blocked people are filtered by the callers.
class RemotePrayerRepository implements PrayerRepository {
  RemotePrayerRepository(
    this._api,
    this._directory, {
    bool Function(String requestId)? isHidden,
  }) : _isHidden = isHidden ?? _never;

  final ApiClient _api;
  final PeopleDirectory _directory;
  final bool Function(String requestId) _isHidden;
  static bool _never(String _) => false;

  final Map<String, PrayerRequest> _seen = {};

  PrayerRequest _request(Map<String, dynamic> j, String communityId) {
    final author = objectOf(j['author']);
    if (author != null) memberFromApi(author, remember: _directory);
    final request = PrayerRequest(
      id: j['id'] as String,
      communityId: (j['community_id'] as String?) ?? communityId,
      authorId: author?['id'] as String?,
      authorName: author?['full_name'] as String?,
      anonymous: author == null,
      body: (j['text'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((j['created_at'] as String?) ?? '') ??
          DateTime.now(),
      prayedCount: (j['prayed_count'] as int?) ?? 0,
      prayedByMe: j['prayed_by_me'] == true,
    );
    _seen[request.id] = request;
    return request;
  }

  @override
  Future<List<PrayerRequest>> getRequests(String communityId) async {
    final items = await _api.getAllItems(
      '/communities/$communityId/prayer-requests',
    );
    return [
      for (final j in items)
        if (!_isHidden(j['id'] as String)) _request(j, communityId),
    ];
  }

  @override
  Future<PrayerRequest> createRequest(
    PrayerRequest request, {
    String? ownerId,
  }) async {
    final json = objectOf(
      await _api.post(
        '/communities/${request.communityId}/prayer-requests',
        headers: {'Idempotency-Key': request.id},
        body: {'text': request.body, 'anonymous': request.anonymous},
      ),
    );
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return _request(json, request.communityId);
  }

  @override
  Future<PrayerRequest?> getRequest(String requestId) async {
    if (_isHidden(requestId)) return null;
    try {
      final json = objectOf(await _api.get('/prayer-requests/$requestId'));
      if (json == null) return null;
      final known = _seen[requestId];
      return _request(json, known?.communityId ?? '');
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<PrayerResponse>> getResponses(String requestId) async {
    final items = await _api.getAllItems(
      '/prayer-requests/$requestId/responses',
    );
    return [for (final j in items) _response(j, requestId)];
  }

  PrayerResponse _response(Map<String, dynamic> j, String requestId) {
    final author = objectOf(j['author']);
    if (author != null) memberFromApi(author, remember: _directory);
    return PrayerResponse(
      id: j['id'] as String,
      requestId: requestId,
      authorId: author?['id'] as String?,
      authorName: author?['full_name'] as String?,
      anonymous: j['anonymous'] == true || author == null,
      body: (j['text'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((j['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  @override
  Future<PrayerResponse> addResponse({
    required String requestId,
    required String body,
    required String authorId,
    required String authorName,
  }) async {
    final json = objectOf(
      await _api.post(
        '/prayer-requests/$requestId/responses',
        body: {'text': body},
      ),
    );
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return _response(json, requestId);
  }

  @override
  Future<PrayerRequest> setPrayed(
    String requestId, {
    required bool prayed,
  }) async {
    final json = objectOf(
      prayed
          ? await _api.put('/prayer-requests/$requestId/prayed')
          : await _api.delete('/prayer-requests/$requestId/prayed'),
    );
    final base = _seen[requestId] ?? await getRequest(requestId);
    if (base == null) throw const ApiException(404, code: 'not_found');
    final updated = base.copyWith(
      prayedCount: (json?['prayed_count'] as int?) ?? base.prayedCount,
      prayedByMe: json?['prayed_by_me'] == true,
    );
    return _seen[requestId] = updated;
  }
}
