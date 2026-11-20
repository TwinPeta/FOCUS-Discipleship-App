import 'package:focus_1/core/utils/initials.dart';
import 'package:focus_1/features/community/data/community_repository.dart';
import 'package:focus_1/features/community/domain/community.dart';
import 'package:focus_1/features/community/domain/person.dart';

class FakeCommunityRepository implements CommunityRepository {
  static const _latency = Duration(milliseconds: 400);

  final Map<String, Community> _byId = {
    'growth-circle': const Community(
      id: 'growth-circle',
      name: 'Growth Circle',
      initials: 'GC',
      type: CommunityType.specific,
      institutionId: '',
      description:
          'A small group that meets weekly to dig into scripture together, pray for '
          "one another and walk through the ordinary ups and downs of student life "
          'alongside mentors who genuinely know your name.',
      meetingDay: 'Every Tuesday',
      meetingTime: '5:00 PM',
      room: 'Room 204, Student Centre',
      superMentor: Person(
        id: 'sm-1',
        name: 'Grace Namuli',
        role: PersonRole.superMentor,
      ),
      mentors: [
        Person(id: 'm-1', name: 'David Okello', role: PersonRole.mentor),
      ],
    ),
    'life-faith-circle': const Community(
      id: 'life-faith-circle',
      name: 'Life & Faith Circle',
      initials: 'LF',
      type: CommunityType.specific,
      institutionId: '',
      description:
          'We explore how faith shapes everyday decisions, from relationships to '
          'career choices, in a relaxed group led by mentors who have walked the '
          'same road.',
      meetingDay: 'Every Thursday',
      meetingTime: '6:30 PM',
      room: 'Chapel Annex, Block B',
      superMentor: Person(
        id: 'sm-2',
        name: 'Esther Uwase',
        role: PersonRole.superMentor,
      ),
      mentors: [
        Person(id: 'm-2', name: 'Samuel Kato', role: PersonRole.mentor),
      ],
    ),
    'freshers-connect': const Community(
      id: 'freshers-connect',
      name: 'Freshers Connect',
      initials: 'FC',
      type: CommunityType.specific,
      institutionId: '',
      description:
          'Built for first-years finding their feet on campus: new friendships, '
          'honest conversations and mentors to help you settle in well.',
      meetingDay: 'Every Friday',
      meetingTime: '4:00 PM',
      room: 'Common Room, Hall 3',
      superMentor: Person(
        id: 'sm-3',
        name: 'Brian Mugisha',
        role: PersonRole.superMentor,
      ),
      mentors: [
        Person(id: 'm-3', name: 'Faith Nabirye', role: PersonRole.mentor),
      ],
    ),
  };

  @override
  Future<Community> getGeneralCommunity(
    String institutionId,
    String institutionName,
  ) async {
    await Future.delayed(_latency);
    return Community(
      id: 'general-$institutionId',
      name: 'General caregroup',
      initials: initialsOf(institutionName),
      type: CommunityType.general,
      institutionId: institutionId,
      description: 'Everyone on your campus, open to all.',
    );
  }

  @override
  Future<List<Community>> getSpecificCommunities(String institutionId) async {
    await Future.delayed(_latency);
    return _byId.values
        .map((c) => c.copyWith(institutionId: institutionId))
        .toList();
  }

  @override
  Future<Community> getCommunityById(String id) async {
    await Future.delayed(_latency);
    final community = _byId[id];
    if (community == null) {
      throw ArgumentError('Unknown caregroup id: $id');
    }
    return community;
  }

  @override
  Future<List<Person>> getMembers(String communityId) async {
    await Future.delayed(_latency);
    final community = _byId[communityId];
    final leadership = [
      if (community?.superMentor != null)
        community!.superMentor!.copyWith(online: true),
      for (final mentor in community?.mentors ?? const <Person>[])
        mentor.copyWith(online: true),
    ];
    const extraMembers = [
      Person(
        id: 'member-1',
        name: 'Faith Nabirye',
        role: PersonRole.member,
        online: true,
      ),
      Person(id: 'member-2', name: 'Peter Ssentongo', role: PersonRole.member),
      Person(
        id: 'member-3',
        name: 'Joy Atim',
        role: PersonRole.member,
        online: true,
      ),
      Person(id: 'member-4', name: 'Isaac Wandera', role: PersonRole.member),
    ];
    return [...leadership, ...extraMembers];
  }
}
