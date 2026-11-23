import '../../../core/network/api_client.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
import '../domain/meeting.dart';
import 'meeting_repository.dart';

/// [MeetingRepository] backed by the FCU API. The server derives the weekly
/// meetings from the community's schedule and decides whether check-in is
/// open by its own clock, so a phone with a wrong clock cannot check in.
class RemoteMeetingRepository implements MeetingRepository {
  RemoteMeetingRepository(this._api, {Outbox? outbox})
    : _outbox = outbox ?? Outbox(api: _api);

  final ApiClient _api;
  final Outbox _outbox;
  final Map<String, Map<String, dynamic>> _seen = {};

  @override
  final CheckInWindow window = const CheckInWindow();

  Meeting _meeting(Map<String, dynamic> j) => _map(_seen[j['id'] as String] = j);

  Meeting _map(Map<String, dynamic> j) => Meeting(
    id: j['id'] as String,
    communityId: (j['community_id'] as String?) ?? '',
    startsAt:
        (DateTime.tryParse((j['starts_at'] as String?) ?? '') ?? DateTime.now())
            .toLocal(),
    room: (j['room'] as String?) ?? '',
    going: j['going'] == true,
    attended: j['attended'] == true,
  );

  String _path(String meetingId) => Uri.encodeComponent(meetingId);

  @override
  Future<MeetingSchedule> getSchedule(
    String communityId, {
    required DateTime now,
  }) async {
    final json = objectOf(
      await _api.get(
        '/communities/$communityId/meetings',
        query: {'now': now.toUtc().toIso8601String()},
      ),
    );
    final next = objectOf(json?['next']);
    final past = json?['past'];
    return MeetingSchedule(
      next: next == null ? null : _meeting(next),
      past: [
        if (past is List)
          for (final j in past.whereType<Map<String, dynamic>>()) _meeting(j),
      ],
    );
  }

  @override
  Future<Meeting> setGoing(String meetingId, {required bool going}) async {
    final json = objectOf(
      (await _outbox.write(
        OfflineWrite(
          method: 'PUT',
          endpoint: '/meetings/${_path(meetingId)}/going',
          entityType: 'meeting_going',
          clientId: 'going-$meetingId-${DateTime.now().microsecondsSinceEpoch}',
          coalesceKey: 'meeting_going:$meetingId',
          body: {'going': going},
          optimistic: {...?_seen[meetingId], 'id': meetingId, 'going': going},
          patch: (_, json) => patchEntity(json, meetingId, (m) {
            m['going'] = going;
            return m;
          }),
        ),
      )).json,
    );
    if (json == null) throw const ApiException(500, message: 'Empty reply');
    return _meeting(json);
  }

  @override
  Future<Meeting> checkIn(String meetingId, {required DateTime now}) async {
    try {
      final json = objectOf(
        await _api.post('/meetings/${_path(meetingId)}/check-in'),
      );
      if (json == null) throw const ApiException(500, message: 'Empty reply');
      return _meeting(json);
    } on ApiException catch (e) {
      if (e.code == 'already_checked_in') throw AlreadyCheckedIn(meetingId);
      if (e.code == 'check_in_closed') throw CheckInClosed(meetingId);
      rethrow;
    }
  }
}
