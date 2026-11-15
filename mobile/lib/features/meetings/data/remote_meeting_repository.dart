import '../../../core/network/api_client.dart';
import '../domain/meeting.dart';
import 'meeting_repository.dart';

/// [MeetingRepository] backed by the FCU API. The server derives the weekly
/// meetings from the community's schedule and decides whether check-in is
/// open by its own clock, so a phone with a wrong clock cannot check in.
class RemoteMeetingRepository implements MeetingRepository {
  RemoteMeetingRepository(this._api);

  final ApiClient _api;

  @override
  final CheckInWindow window = const CheckInWindow();

  Meeting _meeting(Map<String, dynamic> j) => Meeting(
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
      await _api.put(
        '/meetings/${_path(meetingId)}/going',
        body: {'going': going},
      ),
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
