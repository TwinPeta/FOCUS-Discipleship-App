import '../../../core/network/api_client.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
import '../../community/data/community_api_mapper.dart';
import '../../community/data/people_directory.dart';
import '../../feed/domain/post.dart' show PostPhoto;
import '../domain/testimony.dart';
import 'testimony_repository.dart';
import '../../../core/network/media_uploader.dart';

/// [TestimonyRepository] backed by the FCU API. Stories always go to review
/// first (the server enforces it). "Encouraged" reactions are kept on the
/// server (one per member, published stories only).
class RemoteTestimonyRepository implements TestimonyRepository {
  RemoteTestimonyRepository(
    this._api,
    this._directory, {
    bool Function(String testimonyId)? isHidden,
    this.uploader,
    Outbox? outbox,
  }) : _isHidden = isHidden ?? _never,
       _outbox = outbox ?? Outbox(api: _api, uploader: uploader);

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

  /// Uploads a story's photo and video (null in tests without uploads).
  final MediaUploader? uploader;

  final ApiClient _api;
  final PeopleDirectory _directory;
  final bool Function(String testimonyId) _isHidden;
  static bool _never(String _) => false;

  final Map<String, String> _communityOf = {};

  Testimony _map(Map<String, dynamic> j, String communityId) {
    final author = objectOf(j['author']);
    if (author != null) memberFromApi(author, remember: _directory);
    final id = j['id'] as String;
    final media = [
      for (final m in (j['media'] as List?) ?? const [])
        if (m is Map<String, dynamic> && m['url'] is String) m,
    ];
    return Testimony(
      id: id,
      communityId: (j['community_id'] as String?) ?? communityId,
      type: j['format'] == 'video' ? TestimonyType.video : TestimonyType.story,
      title: (j['title'] as String?) ?? '',
      // The detail reply carries the full text; the list only an excerpt.
      excerpt: (j['body'] as String?) ?? (j['excerpt'] as String?),
      authorId: author?['id'] as String?,
      authorName: (author?['full_name'] as String?) ?? 'Member',
      institution: (j['institution_name'] as String?) ?? '',
      status: j['status'] == 'published'
          ? TestimonyStatus.reviewed
          : TestimonyStatus.pending,
      createdAt:
          DateTime.tryParse(
            ((j['created_at'] ?? j['published_at']) as String?) ?? '',
          ) ??
          DateTime.now(),
      encouragedByMe: j['encouraged_by_me'] == true,
      encouragedCount: (j['encouraged_count'] as int?) ?? 0,
      videoUrl: media
          .where((m) => m['kind'] == 'video')
          .map((m) => m['url'] as String)
          .firstOrNull,
      photos: [
        for (final m in media)
          if (m['kind'] == 'image') PostPhoto.network(m['url'] as String),
      ],
    );
  }

  @override
  Future<List<Testimony>> getTestimonies(
    String communityId, {
    required String? viewerId,
  }) async {
    final items = await _api.getAllItems(
      '/communities/$communityId/testimonies',
    );
    return [
      for (final j in items)
        if (!_isHidden(j['id'] as String)) _track(_map(j, communityId)),
    ];
  }

  Testimony _track(Testimony t) {
    _communityOf[t.id] = t.communityId;
    return t;
  }

  @override
  Future<Testimony> submitStory(
    Testimony testimony, {
    StoryAttachments attachments = StoryAttachments.none,
  }) async {
    final media = <LocalMedia>[
      if (uploader != null && attachments.photoPath != null)
        LocalMedia(path: attachments.photoPath!, purpose: 'testimony_photo'),
      if (uploader != null &&
          attachments.videoPath != null &&
          attachments.videoLength != null)
        LocalMedia(
          path: attachments.videoPath!,
          purpose: 'testimony_video',
          duration: attachments.videoLength,
        ),
    ];
    final listPath = '/communities/${testimony.communityId}/testimonies';
    // Waits for review either way, so it is not shown in the saved list.
    final optimistic = <String, dynamic>{
      'id': testimony.id,
      'community_id': testimony.communityId,
      'title': testimony.title,
      'body': testimony.excerpt ?? '',
      'status': 'pending',
      'created_at': apiNow(),
      if (testimony.authorId != null)
        'author': {'id': testimony.authorId, 'full_name': testimony.authorName},
      'pending': true,
    };
    final json = await _write(
      OfflineWrite(
        method: 'POST',
        endpoint: listPath,
        entityType: 'testimony',
        clientId: testimony.id,
        creates: true,
        body: {
          'title': testimony.title,
          'body': testimony.excerpt ?? '',
          'consent': true,
        },
        media: media,
        optimistic: optimistic,
      ),
    );
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return _track(_map(json, testimony.communityId));
  }

  @override
  Future<Testimony?> getTestimony(
    String id, {
    required String? viewerId,
  }) async {
    if (_isHidden(id)) return null;
    try {
      final json = objectOf(await _api.get('/testimonies/$id'));
      if (json == null) return null;
      return _track(_map(json, _communityOf[id] ?? ''));
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      if (e.isNetwork) {
        // Offline and this story's page was never saved: use its copy from
        // a saved list (an excerpt rather than the full text).
        final saved = await _api.findSaved(
          id,
          where: (key) => (cachedPathOf(key) ?? '').contains('/testimonies'),
        );
        if (saved != null) return _track(_map(saved, _communityOf[id] ?? ''));
      }
      rethrow;
    }
  }

  @override
  Future<Testimony> setEncouraged(String id, {required bool encouraged}) async {
    await _outbox.write(
      OfflineWrite(
        method: encouraged ? 'PUT' : 'DELETE',
        endpoint: '/testimonies/$id/encourage',
        entityType: 'testimony_encourage',
        clientId: 'encourage-$id-${_stamp()}',
        coalesceKey: 'testimony_encourage:$id',
        patch: _toggle(id, 'encouraged_by_me', 'encouraged_count', encouraged),
      ),
    );
    // Offline, the saved copy already carries the change.
    final t = await getTestimony(id, viewerId: null);
    if (t == null) throw const ApiException(404, code: 'not_found');
    return t;
  }
}
