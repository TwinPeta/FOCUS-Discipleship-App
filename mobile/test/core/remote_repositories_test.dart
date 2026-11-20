import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/features/community/data/people_directory.dart';
import 'package:focus_1/features/community/data/remote_community_repository.dart';
import 'package:focus_1/features/community/data/remote_membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/domain/person.dart';
import 'package:focus_1/features/feed/data/remote_post_repository.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/messaging/data/messaging_repository.dart';
import 'package:focus_1/features/messaging/data/remote_messaging_repository.dart';
import 'package:focus_1/core/network/media_uploader.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/meetings/data/remote_meeting_repository.dart';
import 'package:focus_1/features/meetings/domain/meeting.dart';
import 'package:focus_1/features/messaging/domain/report.dart';
import 'package:focus_1/features/moderation/data/remote_moderation_queue_repository.dart';
import 'package:focus_1/features/moderation/data/remote_suspension_repository.dart';
import 'package:focus_1/features/moderation/data/remote_warning_repository.dart';
import 'package:focus_1/features/moderation/domain/moderation_case.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Routes "METHOD /v1/path" to a canned reply and records every request.
class _Api {
  _Api(this.routes);

  final Map<String, http.Response Function(http.Request)> routes;
  final List<http.Request> seen = [];

  ApiClient get client => ApiClient(
    baseUrl: 'https://api.test/v1',
    client: MockClient((request) async {
      seen.add(request);
      final route = routes['${request.method} ${request.url.path}'];
      return route == null ? _json(404, {'code': 'not_found'}) : route(request);
    }),
  );
}

Map<String, dynamic> _user(String id, String name, String role) => {
  'id': id,
  'full_name': name,
  'username': name.toLowerCase(),
  'community_role': role,
  'online': false,
};

void main() {
  group('RemoteCommunityRepository', () {
    test(
      'the General caregroup carries leadership and meeting labels',
      () async {
        final api = _Api({
          'GET /v1/me/communities': (_) => _json(200, {
            'general': {
              'community': {'id': 'c-gen'},
              'membership_status': 'member',
            },
            'specific': null,
          }),
          'GET /v1/communities/c-gen': (_) => _json(200, {
            'id': 'c-gen',
            'type': 'general',
            'name': 'General caregroup',
            'initials': 'GE',
            'description': 'Everyone',
            'institution': {'id': 'i1', 'name': 'Makerere University'},
            'meeting': {
              'recurrence': 'weekly',
              'weekday': 'tue',
              'start_time': '17:00',
              'location': 'Room 3',
            },
            'leadership': [
              _user('u1', 'Grace', 'super_mentor'),
              _user('u2', 'David', 'mentor'),
            ],
          }),
        });
        final repo = RemoteCommunityRepository(api.client);

        final c = await repo.getGeneralCommunity('ignored', 'ignored');

        expect(c.id, 'c-gen');
        expect(c.institutionId, 'i1');
        expect(c.meetingDay, 'Every Tuesday');
        expect(c.meetingTime, '5:00 PM');
        expect(c.room, 'Room 3');
        expect(c.superMentor?.id, 'u1');
        expect(c.mentors.map((m) => m.id), ['u2']);
      },
    );
  });

  group('RemoteMembershipRepository', () {
    test(
      'a pending request that becomes a membership is an unseen result',
      () async {
        var status = 'pending';
        final api = _Api({
          'GET /v1/me/communities': (_) => _json(200, {
            'general': null,
            'specific': {
              'community': {'id': 'c1'},
              'membership_status': status,
            },
          }),
        });
        final repo = RemoteMembershipRepository(api.client);

        final pending = await repo.getMembership();
        expect(pending.status, MembershipStatus.pending);

        status = 'member';
        final approved = await repo.getMembership();
        expect(approved.status, MembershipStatus.approved);
        expect(approved.hasUnseenResult, isTrue);

        final seen = await repo.markResultSeen();
        expect(seen.hasUnseenResult, isFalse);
      },
    );

    test('a declined request shows its note until it is cleared', () async {
      final api = _Api({
        'GET /v1/me/communities': (_) =>
            _json(200, {'general': null, 'specific': null}),
        'GET /v1/me/join-requests': (_) => _json(200, {
          'items': [
            {
              'id': 'jr1',
              'status': 'rejected',
              'note': 'Not this term',
              'created_at': '2026-01-01T00:00:00Z',
              'community': {'id': 'c1'},
            },
          ],
        }),
      });
      final repo = RemoteMembershipRepository(api.client);

      final declined = await repo.getMembership();
      expect(declined.status, MembershipStatus.rejected);
      expect(declined.message, 'Not this term');

      expect((await repo.clear()).status, MembershipStatus.none);
      expect((await repo.getMembership()).status, MembershipStatus.none);
    });

    test(
      'requesting while another caregroup is active hits the limit',
      () async {
        final api = _Api({
          'GET /v1/me/communities': (_) => _json(200, {
            'general': null,
            'specific': {
              'community': {'id': 'other'},
              'membership_status': 'member',
            },
          }),
        });
        final repo = RemoteMembershipRepository(api.client);
        await expectLater(
          repo.requestToJoin('c1'),
          throwsA(isA<MembershipLimitReached>()),
        );
      },
    );

    test('leaving calls the API and clears the membership', () async {
      final api = _Api({
        'GET /v1/me/communities': (_) => _json(200, {
          'general': null,
          'specific': {
            'community': {'id': 'c1'},
            'membership_status': 'member',
          },
        }),
        'DELETE /v1/communities/c1/membership': (_) => _json(204, null),
      });
      final repo = RemoteMembershipRepository(api.client);
      final left = await repo.leave();
      expect(left.status, MembershipStatus.none);
      expect(api.seen.last.method, 'DELETE');
    });
  });

  group('RemotePostRepository', () {
    Map<String, dynamic> post({bool liked = false}) => {
      'id': 'p1',
      'community_id': 'c1',
      'author': _user('u1', 'Grace', 'super_mentor'),
      'text': 'Hello',
      'media': [
        {'kind': 'image', 'url': 'https://cdn.test/a.jpg'},
      ],
      'like_count': liked ? 3 : 2,
      'liked_by_me': liked,
      'comment_count': 1,
      'created_at': '2026-01-01T10:00:00Z',
    };

    RemotePostRepository repo(_Api api) => RemotePostRepository(
      api.client,
      MediaUploader(api.client),
      PeopleDirectory(),
    );

    test('maps a post with its photo and role badge', () async {
      final api = _Api({
        'GET /v1/communities/c1/posts': (_) => _json(200, {
          'items': [post()],
          'next_cursor': 'abc',
        }),
      });
      final page = await repo(api).getPosts('c1', PostScope.specific);

      expect(page.nextCursor, 'abc');
      final p = page.items.single;
      expect(p.roleLabel, 'Super-mentor');
      expect(p.photo?.url, 'https://cdn.test/a.jpg');
      expect(p.author.role, PersonRole.superMentor);
    });

    test('liking uses the server counts', () async {
      final api = _Api({
        'GET /v1/communities/c1/posts': (_) => _json(200, {
          'items': [post()],
        }),
        'PUT /v1/posts/p1/like': (_) =>
            _json(200, {'like_count': 3, 'liked_by_me': true}),
      });
      final posts = repo(api);
      await posts.getPosts('c1', PostScope.specific);

      final liked = await posts.setLiked('p1', liked: true);

      expect(liked.likeCount, 3);
      expect(liked.likedByMe, isTrue);
    });

    test(
      'creating a post sends an idempotency key and returns the stored post',
      () async {
        final api = _Api({
          'POST /v1/communities/c1/posts': (_) => _json(201, post()),
        });
        final stored = await repo(api).createPost(
          Post(
            id: 'local-1',
            communityId: 'c1',
            scope: PostScope.specific,
            author: const Person(id: 'me', name: 'Me', role: PersonRole.member),
            body: 'Hello',
            createdAt: DateTime(2026),
          ),
        );
        final request = api.seen.single;
        expect(request.headers['Idempotency-Key'], 'local-1');
        expect(jsonDecode(request.body)['text'], 'Hello');
        expect(stored.id, 'p1'); // the server's id replaces the local one
      },
    );

    test('a hidden post stays out of the feed', () async {
      final api = _Api({
        'GET /v1/communities/c1/posts': (_) => _json(200, {
          'items': [post()],
        }),
        'PUT /v1/posts/p1/hide': (_) => _json(204, null),
      });
      final posts = repo(api);
      await posts.hidePost('p1');
      // Saved on the server; this session also leaves it out straight away.
      expect(api.seen.map((r) => '${r.method} ${r.url.path}'), [
        'PUT /v1/posts/p1/hide',
      ]);
      final page = await posts.getPosts('c1', PostScope.specific);
      expect(page.items, isEmpty);
    });
  });

  group('RemoteMessagingRepository', () {
    RemoteMessagingRepository repo(_Api api) =>
        RemoteMessagingRepository(api.client, myId: () => 'me-id');

    test('messages read oldest first and mine are marked', () async {
      final api = _Api({
        'GET /v1/conversations/t1/messages': (_) => _json(200, {
          'items': [
            {
              'id': 'm2',
              'sender_id': 'me-id',
              'text': 'B',
              'sent_at': '2026-01-01T10:01:00Z',
            },
            {
              'id': 'm1',
              'sender_id': 'u9',
              'text': 'A',
              'sent_at': '2026-01-01T10:00:00Z',
            },
          ],
        }),
      });
      final messages = await repo(api).getMessages('t1');
      expect(messages.map((m) => m.id), ['m1', 'm2']);
      expect(messages.map((m) => m.isMine), [false, true]);
    });

    test(
      'the under-18 limit from the server becomes MessagingRestricted',
      () async {
        final api = _Api({
          'POST /v1/conversations': (_) =>
              _json(403, {'code': 'messaging_restricted'}),
        });
        await expectLater(
          repo(api).openOrCreateThread(
            const Person(id: 'u9', name: 'Adult', role: PersonRole.member),
            'Member',
          ),
          throwsA(isA<MessagingRestricted>()),
        );
      },
    );
  });

  group('RemoteMeetingRepository', () {
    Map<String, dynamic> meeting({bool attended = false}) => {
      'id': 'c1@2026-05-12',
      'community_id': 'c1',
      'starts_at': '2026-05-12T14:00:00Z',
      'room': 'Room 3',
      'going': true,
      'attended': attended,
    };

    test('maps the schedule', () async {
      final api = _Api({
        'GET /v1/communities/c1/meetings': (_) => _json(200, {
          'next': meeting(),
          'past': [meeting(attended: true)],
        }),
      });
      final schedule = await RemoteMeetingRepository(api.client)
          .getSchedule('c1', now: DateTime(2026, 5, 12));
      expect(schedule.next?.room, 'Room 3');
      expect(schedule.next?.going, isTrue);
      expect(schedule.past.single.attended, isTrue);
      expect(api.seen.single.url.queryParameters['now'], isNotNull);
    });

    test('check-in errors become the app exceptions', () async {
      var code = 'check_in_closed';
      final api = _Api({
        'POST /v1/meetings/c1%402026-05-12/check-in': (_) =>
            _json(409, {'code': code}),
      });
      final repo = RemoteMeetingRepository(api.client);
      await expectLater(
        repo.checkIn('c1@2026-05-12', now: DateTime.now()),
        throwsA(isA<CheckInClosed>()),
      );
      code = 'already_checked_in';
      await expectLater(
        repo.checkIn('c1@2026-05-12', now: DateTime.now()),
        throwsA(isA<AlreadyCheckedIn>()),
      );
    });
  });

  group('RemoteModerationQueueRepository', () {
    final caseJson = {
      'id': 'post:p1',
      'community_id': 'c1',
      'content': 'post',
      'target_id': 'p1',
      'author': {'id': 'u1', 'full_name': 'Isaac'},
      'preview': 'Rude post',
      'reason': 'harassment_bullying',
      'report_count': 2,
      'first_reporter_name': 'Aisha',
      'reported_at': '2026-05-01T10:00:00Z',
      'level': 1,
    };

    test('only a super-mentor can open the queue', () async {
      final repo = RemoteModerationQueueRepository(_Api({}).client);
      await expectLater(
        repo.getOpenCases('c1', actorRole: UserRole.student),
        throwsA(isA<NotSuperMentor>()),
      );
    });

    test('lists cases, then warning one hides it on this device', () async {
      final api = _Api({
        'GET /v1/communities/c1/moderation/cases': (_) => _json(200, {
          'items': [caseJson],
        }),
        'POST /v1/communities/c1/moderation/cases/post%3Ap1/action': (_) =>
            _json(200, {...caseJson, 'outcome': 'warned'}),
      });
      final repo = RemoteModerationQueueRepository(api.client);

      final open = await repo.getOpenCases(
        'c1',
        actorRole: UserRole.superMentor,
      );
      expect(open.single.reason, ReportReason.harassment);
      expect(open.single.reportCount, 2);
      expect(open.single.authorId, 'u1');
      expect(repo.isHidden('p1'), isFalse);

      final done = await repo.warnAuthor(
        'post:p1',
        actorRole: UserRole.superMentor,
      );
      expect(done.outcome, ModerationOutcome.warned);
      expect(done.isOpen, isFalse);
      expect(jsonDecode(api.seen.last.body), {'action': 'warn'});
      expect(repo.isHidden('p1'), isTrue);
    });

    test('acting on a closed case says so', () async {
      final api = _Api({
        'GET /v1/communities/c1/moderation/cases': (_) => _json(200, {
          'items': [caseJson],
        }),
        'POST /v1/communities/c1/moderation/cases/post%3Ap1/action': (_) =>
            _json(409, {'code': 'case_closed'}),
      });
      final repo = RemoteModerationQueueRepository(api.client);
      await repo.getOpenCases('c1', actorRole: UserRole.superMentor);
      await expectLater(
        repo.keep('post:p1', actorRole: UserRole.superMentor),
        throwsA(isA<ModerationCaseClosed>()),
      );
    });
  });

  group('warnings and suspension', () {
    test('warnings list and acknowledge', () async {
      final warning = {
        'id': 'w1',
        'reason': 'Harassment or bullying',
        'preview': 'Rude post',
        'created_at': '2026-05-01T10:00:00Z',
        'acknowledged': false,
      };
      final api = _Api({
        'GET /v1/me/warnings': (_) => _json(200, {
          'items': [warning],
        }),
        'POST /v1/me/warnings/w1/acknowledge': (_) =>
            _json(200, {...warning, 'acknowledged': true}),
      });
      final repo = RemoteWarningRepository(api.client, myId: () => 'me-id');
      final list = await repo.getWarningsFor('me-id');
      expect(list.single.acknowledged, isFalse);
      expect(list.single.userId, 'me-id');
      expect((await repo.acknowledge('w1')).acknowledged, isTrue);
    });

    test('a suspension has a reason and an end; none means null', () async {
      var body = <String, dynamic>{
        'suspension': {
          'reason': 'Breaking the rules',
          'until': '2099-01-01T00:00:00Z',
        },
      };
      final api = _Api({'GET /v1/me/suspension': (_) => _json(200, body)});
      final repo = RemoteSuspensionRepository(api.client);

      final s = await repo.getSuspension('me-id');
      expect(s?.reason, 'Breaking the rules');
      expect(s?.isActiveAt(DateTime(2026)), isTrue);

      body = {'suspension': null};
      expect(await repo.getSuspension('me-id'), isNull);
    });
  });
}
