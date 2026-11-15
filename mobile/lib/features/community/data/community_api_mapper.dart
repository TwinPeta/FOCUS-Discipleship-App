import '../../../core/network/api_client.dart';
import '../domain/community.dart';
import '../domain/join_request.dart';
import '../domain/member_profile.dart';
import '../domain/person.dart';
import 'people_directory.dart';

PersonRole roleFromApi(String? role) {
  switch (role) {
    case 'super_mentor':
      return PersonRole.superMentor;
    case 'mentor':
      return PersonRole.mentor;
    default:
      return PersonRole.member;
  }
}

/// API `UserRef` -> [Person].
Person personFromApi(Map<String, dynamic> j) => Person(
  id: j['id'] as String,
  name: (j['full_name'] as String?) ?? '',
  role: roleFromApi(j['community_role'] as String?),
  online: j['online'] == true,
);

/// API `UserRef` -> [MemberProfile] (no bio or badges: the API does not
/// expose them for other people).
MemberProfile memberFromApi(
  Map<String, dynamic> j, {
  String? communityName,
  PeopleDirectory? remember,
}) {
  final profile = MemberProfile(
    person: personFromApi(j),
    username: (j['username'] as String?) ?? '',
    communityName: communityName,
  );
  remember?.put(profile);
  return profile;
}

const _weekdays = {
  'mon': 'Monday',
  'tue': 'Tuesday',
  'wed': 'Wednesday',
  'thu': 'Thursday',
  'fri': 'Friday',
  'sat': 'Saturday',
  'sun': 'Sunday',
};

/// '17:00' -> '5:00 PM'.
String? timeLabel(String? hhmm) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return hhmm;
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
}

/// API `CommunitySummary` or `Community` -> [Community].
Community communityFromApi(Map<String, dynamic> j) {
  final meeting = objectOf(j['meeting']);
  final institution = objectOf(j['institution']);
  final day = _weekdays[meeting?['weekday']];
  final leadership = (j['leadership'] is List)
      ? (j['leadership'] as List).whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];

  Person? superMentor;
  final superRaw = objectOf(j['super_mentor']);
  if (superRaw != null) superMentor = personFromApi(superRaw);
  for (final l in leadership) {
    if (superMentor == null && l['community_role'] == 'super_mentor') {
      superMentor = personFromApi(l);
    }
  }

  return Community(
    id: j['id'] as String,
    name: (j['name'] as String?) ?? '',
    initials: (j['initials'] as String?) ?? '',
    type: j['type'] == 'general' ? CommunityType.general : CommunityType.specific,
    institutionId: (institution?['id'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    meetingDay: day == null
        ? null
        : (meeting?['recurrence'] == 'weekly' ? 'Every $day' : day),
    meetingTime: timeLabel(meeting?['start_time'] as String?),
    room: meeting?['location'] as String?,
    superMentor: superMentor,
    mentors: [
      for (final l in leadership)
        if (l['community_role'] == 'mentor') personFromApi(l),
    ],
  );
}

/// API `JoinRequest` -> the super-mentor's [JoinRequest].
JoinRequest joinRequestFromApi(Map<String, dynamic> j) {
  final community = objectOf(j['community']) ?? const <String, dynamic>{};
  final user = objectOf(j['user']) ?? const <String, dynamic>{};
  final institution = objectOf(community['institution']);
  JoinRequestStatus status;
  switch (j['status']) {
    case 'approved':
      status = JoinRequestStatus.approved;
    case 'rejected' || 'cancelled':
      status = JoinRequestStatus.declined;
    default:
      status = JoinRequestStatus.pending;
  }
  return JoinRequest(
    id: j['id'] as String,
    communityId: (community['id'] as String?) ?? '',
    studentId: (user['id'] as String?) ?? '',
    studentName: (user['full_name'] as String?) ?? '',
    username: (user['username'] as String?) ?? '',
    institution: (institution?['name'] as String?) ?? '',
    requestedAt: DateTime.tryParse((j['created_at'] as String?) ?? '') ??
        DateTime.now(),
    status: status,
    message: j['note'] as String?,
  );
}
