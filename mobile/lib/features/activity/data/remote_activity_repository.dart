import '../../../core/network/api_client.dart';
import '../../../core/utils/slug.dart';
import '../../community/domain/user_role.dart';
import '../domain/activity_event.dart';
import '../domain/badge.dart';
import 'activity_repository.dart';

/// [ActivityRepository] backed by the FCU API. The server records activity
/// itself when a video, resource, quiz, prayer or pathway step is completed,
/// so [record] only reports which badges were newly earned since last look.
class RemoteActivityRepository implements ActivityRepository {
  RemoteActivityRepository(this._api);

  final ApiClient _api;
  Set<String>? _earned;

  static ActivityType? _type(String? t) {
    switch (t) {
      case 'video_watched':
        return ActivityType.videoWatched;
      case 'resource_completed':
        return ActivityType.devotionalRead;
      case 'quiz_completed':
        return ActivityType.quizCompleted;
      case 'prayed':
        return ActivityType.prayed;
      case 'pathway_step_completed':
        return ActivityType.pathwayCompleted;
      case 'meeting_attended':
        return ActivityType.meetingAttended;
      default:
        return null; // posts, testimonies... are not shown in My activity
    }
  }

  Future<Map<String, dynamic>?> _activity() async =>
      objectOf(await _api.get('/me/activity', query: {'limit': '50'}));

  List<AppBadge> _badges(Map<String, dynamic>? json) {
    final raw = json?['badges'];
    final list = raw is List
        ? raw.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final badges = [
      for (final b in list)
        AppBadge(
          id: slugify((b['name'] as String?) ?? ''),
          name: (b['name'] as String?) ?? '',
          earned: b['earned'] == true,
        ),
    ];
    _earned = {
      for (final b in badges)
        if (b.earned) b.id,
    };
    return badges;
  }

  @override
  Future<List<ActivityEvent>> getEvents() async {
    final json = await _activity();
    return [
      for (final e in itemsOf(objectOf(json?['recent'])))
        if (_type(e['type'] as String?) case final type?)
          ActivityEvent(
            type: type,
            label: (e['label'] as String?) ?? '',
            at:
                DateTime.tryParse((e['occurred_at'] as String?) ?? '') ??
                DateTime.now(),
            sourceId: e['id'] as String?,
          ),
    ];
  }

  @override
  Future<List<AppBadge>> getBadges() async => _badges(await _activity());

  @override
  Future<List<AppBadge>> record(ActivityEvent event) async {
    final before = _earned;
    final badges = _badges(await _activity());
    if (before == null) return const [];
    return [
      for (final b in badges)
        if (b.earned && !before.contains(b.id)) b,
    ];
  }

  @override
  Future<Map<String, DateTime>> lastActiveByMember(
    String communityId, {
    required UserRole? actorRole,
  }) async {
    if (actorRole != UserRole.superMentor) throw NotSuperMentor(communityId);
    final json = await _api.get(
      '/communities/$communityId/members/last-active',
    );
    return {
      for (final j in itemsOf(json))
        j['user_id'] as String: ?DateTime.tryParse(
          (j['last_active_at'] as String?) ?? '',
        ),
    };
  }
}
