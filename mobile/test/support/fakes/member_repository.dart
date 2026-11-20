import 'package:focus_1/features/activity/domain/badge.dart';
import 'package:focus_1/features/community/data/member_repository.dart';
import 'package:focus_1/features/community/domain/member_profile.dart';
import 'package:focus_1/features/community/domain/person.dart';

extension on MemberProfile {
  /// Keeps the roster's live fields (online) on the directory entry.
  MemberProfile withPerson(Person p) => MemberProfile(
    person: p,
    username: username,
    bio: bio,
    institution: institution,
    communityName: communityName,
    badges: badges,
  );
}

class FakeMemberRepository implements MemberRepository {
  FakeMemberRepository({
    this.latency = const Duration(milliseconds: 300),
    required this.roster,
    bool Function(String userId)? isBlocked,
  }) : _isBlocked = isBlocked ?? _nobody;

  final Duration latency;

  /// The community's people (from `CommunityRepository.getMembers`).
  final Future<List<Person>> Function(String communityId) roster;
  final bool Function(String userId) _isBlocked;
  static bool _nobody(String _) => false;

  static List<AppBadge> _earned(List<String> ids) => [
    for (final b in kBadgeCatalog)
      if (ids.contains(b.id)) b.copyWith(earned: true),
  ];

  /// Seeded people, keyed by the ids the other fake repositories use.
  static final Map<String, MemberProfile> _directory = {
    for (final m in [
      MemberProfile(
        person: const Person(
          id: 'sm-1',
          name: 'Grace Namuli',
          role: PersonRole.superMentor,
        ),
        username: 'grace.namuli',
        bio: 'Super-mentor of Growth Circle. Loves long walks and good tea.',
        communityName: 'Growth Circle',
        badges: _earned(['first-steps', 'prayer-partner', 'pathway-complete']),
      ),
      MemberProfile(
        person: const Person(
          id: 'sm-2',
          name: 'Esther Uwase',
          role: PersonRole.superMentor,
        ),
        username: 'esther.uwase',
        bio: 'Leading Life & Faith Circle this year.',
        communityName: 'Life & Faith Circle',
        badges: _earned(['first-steps', 'quiz-finisher']),
      ),
      MemberProfile(
        person: const Person(
          id: 'sm-3',
          name: 'Brian Mugisha',
          role: PersonRole.superMentor,
        ),
        username: 'brian.mugisha',
        bio: 'Here to help freshers find their feet.',
        communityName: 'Freshers Connect',
        badges: _earned(['first-steps']),
      ),
      MemberProfile(
        person: const Person(
          id: 'm-1',
          name: 'David Okello',
          role: PersonRole.mentor,
        ),
        username: 'david.okello',
        bio: 'Mentor. Ask me about early-morning prayer walks.',
        communityName: 'Growth Circle',
        badges: _earned(['first-steps', 'prayer-partner']),
      ),
      MemberProfile(
        person: const Person(
          id: 'm-2',
          name: 'Samuel Kato',
          role: PersonRole.mentor,
        ),
        username: 'samuel.kato',
        communityName: 'Life & Faith Circle',
        badges: _earned(['first-steps']),
      ),
      const MemberProfile(
        person: Person(
          id: 'm-3',
          name: 'Faith Nabirye',
          role: PersonRole.mentor,
        ),
        username: 'faith.mentor',
        communityName: 'Freshers Connect',
      ),
      MemberProfile(
        person: const Person(
          id: 'member-1',
          name: 'Faith Nabirye',
          role: PersonRole.member,
        ),
        username: 'faithn',
        bio: 'Second-year nursing student.',
        communityName: 'Growth Circle',
        badges: _earned(['first-steps', 'prayer-partner']),
      ),
      MemberProfile(
        person: const Person(
          id: 'member-2',
          name: 'Peter Ssentongo',
          role: PersonRole.member,
        ),
        username: 'peter.ss',
        communityName: 'Growth Circle',
        badges: _earned(['first-steps']),
      ),
      MemberProfile(
        person: const Person(
          id: 'member-3',
          name: 'Joy Atim',
          role: PersonRole.member,
        ),
        username: 'joyatim',
        bio: 'Choir, coffee and computer science.',
        communityName: 'Growth Circle',
        badges: _earned(['quiz-finisher']),
      ),
      const MemberProfile(
        person: Person(
          id: 'member-4',
          name: 'Isaac Wandera',
          role: PersonRole.member,
        ),
        username: 'isaacw',
        communityName: 'Growth Circle',
      ),
      const MemberProfile(
        person: Person(
          id: 'campus-team-1',
          name: 'FCU Campus Team',
          role: PersonRole.superMentor,
        ),
        username: 'fcu.campus',
        bio: 'News and events for everyone on campus.',
        communityName: 'General caregroup',
      ),
      const MemberProfile(
        person: Person(
          id: 'student-1',
          name: 'Joseph Mwangi',
          role: PersonRole.member,
        ),
        username: 'joseph.m',
        communityName: 'General caregroup',
      ),
      MemberProfile(
        person: const Person(
          id: 'student-2',
          name: 'Patience Achieng',
          role: PersonRole.member,
        ),
        username: 'patience.a',
        communityName: 'General caregroup',
        badges: _earned(['first-steps']),
      ),
    ])
      m.person.id: m,
  };

  @override
  Future<MemberProfile?> getMember(String id) async {
    await Future.delayed(latency);
    return _directory[id];
  }

  @override
  Future<List<MemberProfile>> getCommunityMembers(String communityId) async {
    final people = await roster(communityId);
    await Future.delayed(latency);
    return [
      for (final p in people)
        if (!_isBlocked(p.id))
          (_directory[p.id] ?? MemberProfile(person: p, username: p.id))
              .withPerson(p),
    ];
  }
}
