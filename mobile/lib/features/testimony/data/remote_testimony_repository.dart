import '../../../core/network/api_client.dart';
import '../../community/data/community_api_mapper.dart';
import '../../community/data/people_directory.dart';
import '../domain/testimony.dart';
import 'testimony_repository.dart';
import '../../../core/network/media_uploader.dart';

/// [TestimonyRepository] backed by the FCU API. Stories always go to review
/// first (the server enforces it). The API has no "Encouraged" reaction yet,
/// so it is remembered on the device for this session only.
class RemoteTestimonyRepository implements TestimonyRepository {
  RemoteTestimonyRepository(
    this._api,
    this._directory, {
    bool Function(String testimonyId)? isHidden,
    this.uploader,
  }) : _isHidden = isHidden ?? _never;

  /// Uploads a story's photo and video (null in tests without uploads).
  final MediaUploader? uploader;

  final ApiClient _api;
  final PeopleDirectory _directory;
  final bool Function(String testimonyId) _isHidden;
  static bool _never(String _) => false;

  final Set<String> _encouraged = {};
  final Map<String, String> _communityOf = {};

  Testimony _map(Map<String, dynamic> j, String communityId) {
    final author = objectOf(j['author']);
    if (author != null) memberFromApi(author, remember: _directory);
    final id = j['id'] as String;
    final mine = _encouraged.contains(id);
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
      encouragedByMe: mine,
      encouragedCount: mine ? 1 : 0,
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
    final mediaIds = <String>[];
    final uploader = this.uploader;
    if (uploader != null) {
      if (attachments.photoPath != null) {
        mediaIds.add(
          await uploader.uploadPhoto(
            attachments.photoPath!,
            purpose: 'testimony_photo',
          ),
        );
      }
      if (attachments.videoPath != null && attachments.videoLength != null) {
        mediaIds.add(
          await uploader.uploadVideo(
            attachments.videoPath!,
            duration: attachments.videoLength!,
          ),
        );
      }
    }
    final json = objectOf(
      await _api.post(
        '/communities/${testimony.communityId}/testimonies',
        body: {
          'title': testimony.title,
          'body': testimony.excerpt ?? '',
          'consent': true,
          if (mediaIds.isNotEmpty) 'media_ids': mediaIds,
        },
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
      rethrow;
    }
  }

  @override
  Future<Testimony> setEncouraged(String id, {required bool encouraged}) async {
    if (encouraged) {
      _encouraged.add(id);
    } else {
      _encouraged.remove(id);
    }
    final t = await getTestimony(id, viewerId: null);
    if (t == null) throw const ApiException(404, code: 'not_found');
    return t;
  }
}
