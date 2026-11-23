import '../../../core/network/api_client.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
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
    Outbox? outbox,
  }) : _isHidden = isHidden ?? _never,
       _outbox = outbox ?? Outbox(api: _api);

  final ApiClient _api;
  final Outbox _outbox;

  Future<Map<String, dynamic>?> _write(OfflineWrite write) async =>
      objectOf((await _outbox.write(write)).json);

  static String _stamp() => '${DateTime.now().microsecondsSinceEpoch}';

  /// Flips a `<flag>` / `<count>` pair on the saved copies of [id].
  static Object? Function(String, Object?) _toggle(
    String id,
    String flag,
    String count,
    bool on,
  ) => (_, json) => patchEntity(json, id, (m) {
    if ((m[flag] == true) == on) return m;
    m[flag] = on;
    final n = ((m[count] as int?) ?? 0) + (on ? 1 : -1);
    m[count] = n < 0 ? 0 : n;
    return m;
  });

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
      responseCount: (j['response_count'] as int?) ?? 0,
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
    final listPath = '/communities/${request.communityId}/prayer-requests';
    final author = request.anonymous ? null : (request.authorId ?? ownerId);
    final optimistic = <String, dynamic>{
      'id': request.id,
      'community_id': request.communityId,
      if (author != null)
        'author': {'id': author, 'full_name': request.authorName ?? ''},
      'text': request.body,
      'anonymous': request.anonymous,
      'created_at': apiNow(),
      'prayed_count': 0,
      'prayed_by_me': false,
      'response_count': 0,
      'pending': true,
    };
    final json = await _write(
      OfflineWrite(
        method: 'POST',
        endpoint: listPath,
        entityType: 'prayer',
        clientId: request.id,
        creates: true,
        body: {'text': request.body, 'anonymous': request.anonymous},
        optimistic: optimistic,
        patchWhere: firstPageOf(listPath),
        patch: (_, json) => insertItem(json, optimistic),
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
    final listPath = '/prayer-requests/$requestId/responses';
    final id = 'response-${_stamp()}';
    final optimistic = <String, dynamic>{
      'id': id,
      'author': {'id': authorId, 'full_name': authorName},
      'text': body,
      'created_at': apiNow(),
      'pending': true,
    };
    final json = await _write(
      OfflineWrite(
        method: 'POST',
        endpoint: listPath,
        entityType: 'prayer_response',
        clientId: id,
        creates: true,
        body: {'text': body},
        optimistic: optimistic,
        patch: (key, json) => cachedPathOf(key) == listPath
            ? insertItem(json, optimistic, atEnd: true)
            : patchEntity(json, requestId, (m) {
                m['response_count'] = ((m['response_count'] as int?) ?? 0) + 1;
                return m;
              }),
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
    final known = _seen[requestId];
    final json = await _write(
      OfflineWrite(
        method: prayed ? 'PUT' : 'DELETE',
        endpoint: '/prayer-requests/$requestId/prayed',
        entityType: 'prayer_prayed',
        clientId: 'prayed-$requestId-${_stamp()}',
        coalesceKey: 'prayer_prayed:$requestId',
        optimistic: {
          if (known != null)
            'prayed_count': known.prayedByMe == prayed
                ? known.prayedCount
                : known.prayedCount + (prayed ? 1 : -1),
          'prayed_by_me': prayed,
        },
        patch: _toggle(requestId, 'prayed_by_me', 'prayed_count', prayed),
      ),
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
