import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/community/data/remote_membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/presentation/providers/membership_provider.dart';
import 'package:focus_1/features/notifications/presentation/notification_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fake_backend.dart';
import '../support/fakes.dart';

http.Response _json(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Routes "METHOD /v1/path" to a canned reply and records every request.
class _Api {
  _Api(this.routes);

  final Map<String, http.Response Function(http.Request)> routes;
  final List<String> seen = [];

  ApiClient get client => ApiClient(
    baseUrl: 'https://api.test/v1',
    client: MockClient((request) async {
      final key = '${request.method} ${request.url.path}';
      seen.add(key);
      final route = routes[key];
      return route == null ? _json(404, {'code': 'not_found'}) : route(request);
    }),
  );
}

/// `GET /me/communities` as `api/src/routes/me.js` returns it.
Map<String, dynamic> _mine(String? communityId, String status) => {
  'general': null,
  'specific': communityId == null
      ? null
      : {
          'community': {'id': communityId},
          'membership_status': status,
          'joined_at': null,
        },
};

/// A `JoinRequest` as `joinRequestDto` returns it.
Map<String, dynamic> _request(String id, String communityId, String status) => {
  'id': id,
  'community': {'id': communityId},
  'user': {'id': 'me'},
  'status': status,
  'created_at': '2026-11-15T08:00:00Z',
  'decided_at': null,
  'note': null,
};

class _CountingMembership extends FakeMembershipRepository {
  _CountingMembership() : super(latency: Duration.zero);

  int reads = 0;

  @override
  Future<Membership> getMembership() {
    reads++;
    return super.getMembership();
  }
}

void main() {
  group('RemoteMembershipRepository against the API shapes', () {
    test('cancelling deletes the pending request and clears it', () async {
      var specific = 'c1';
      final api = _Api({
        'GET /v1/me/communities': (_) => _json(
          200,
          specific.isEmpty ? _mine(null, '') : _mine(specific, 'pending'),
        ),
        'GET /v1/me/join-requests': (_) => _json(200, {
          'items': [
            if (specific.isNotEmpty) _request('jr1', 'c1', 'pending'),
            if (specific.isEmpty) _request('jr1', 'c1', 'cancelled'),
          ],
        }),
        'DELETE /v1/join-requests/jr1': (_) {
          specific = '';
          return _json(204, null);
        },
      });
      final repo = RemoteMembershipRepository(api.client);
      expect((await repo.getMembership()).status, MembershipStatus.pending);

      final after = await repo.cancelRequest();
      expect(after.status, MembershipStatus.none);
      expect(api.seen, contains('DELETE /v1/join-requests/jr1'));
    });

    test(
      'cancelling a request decided meanwhile returns the decision',
      () async {
        var status = 'pending';
        final api = _Api({
          'GET /v1/me/communities': (_) => _json(200, _mine('c1', status)),
          'GET /v1/me/join-requests': (_) => _json(200, {
            'items': [_request('jr1', 'c1', 'pending')],
          }),
          'DELETE /v1/join-requests/jr1': (_) {
            status = 'member'; // the super-mentor approved first
            return _json(409, {'code': 'not_pending'});
          },
        });
        final repo = RemoteMembershipRepository(api.client);
        await repo.getMembership();
        final after = await repo.cancelRequest();
        expect(after.status, MembershipStatus.approved);
        expect(after.hasUnseenResult, isTrue);
      },
    );

    test('cancelling with nothing pending throws', () async {
      final api = _Api({
        'GET /v1/me/communities': (_) => _json(200, _mine('c1', 'member')),
      });
      await expectLater(
        RemoteMembershipRepository(api.client).cancelRequest(),
        throwsA(isA<IllegalMembershipTransition>()),
      );
    });

    test(
      '409 community_limit_reached reports the community the server knows',
      () async {
        var requested = false;
        final api = _Api({
          // First read: nothing (stale); after the 409 the server's pending
          // request for another community, made on another device.
          'GET /v1/me/communities': (_) =>
              _json(200, requested ? _mine('c2', 'pending') : _mine(null, '')),
          'GET /v1/me/join-requests': (_) => _json(200, {'items': []}),
          'POST /v1/communities/c1/join-requests': (_) {
            requested = true;
            return _json(409, {'code': 'community_limit_reached'});
          },
        });
        await expectLater(
          RemoteMembershipRepository(api.client).requestToJoin('c1'),
          throwsA(
            isA<MembershipLimitReached>().having(
              (e) => e.existingCommunityId,
              'existingCommunityId',
              'c2',
            ),
          ),
        );
      },
    );
  });

  group('MembershipController', () {
    test('cancelRequest moves pending back to none', () async {
      final c = fakeContainer(
        overrides: [
          membershipRepositoryProvider.overrideWith(
            (ref) => FakeMembershipRepository(latency: Duration.zero),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(membershipProvider.future);
      await c.read(membershipProvider.notifier).requestToJoin('c1');
      expect(
        c.read(membershipProvider).value?.status,
        MembershipStatus.pending,
      );
      await c.read(membershipProvider.notifier).cancelRequest();
      expect(c.read(membershipProvider).value?.status, MembershipStatus.none);
    });

    test(
      'while pending it re-reads on the poll interval (socket missed)',
      () async {
        final repo = _CountingMembership();
        final c = fakeContainer(
          overrides: [
            membershipRepositoryProvider.overrideWith((ref) => repo),
            notificationPollIntervalProvider.overrideWithValue(
              const Duration(milliseconds: 20),
            ),
          ],
        );
        addTearDown(c.dispose);
        final sub = c.listen(membershipProvider, (_, _) {});
        addTearDown(sub.close);
        await c.read(membershipProvider.future);
        await c.read(membershipProvider.notifier).requestToJoin('c1');
        // requestToJoin wrote the state; force one rebuild to arm the timer.
        c.invalidate(membershipProvider);
        await c.read(membershipProvider.future);
        final before = repo.reads;

        await repo.debugApprove(); // decided on the super-mentor's side
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await c.read(membershipProvider.future);
        expect(repo.reads, greaterThan(before));
        expect(
          c.read(membershipProvider).value?.status,
          MembershipStatus.approved,
        );

        // Not pending any more: no further polling.
        final settled = repo.reads;
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(repo.reads, settled);
      },
    );

    test('a limit error refreshes the membership before rethrowing', () async {
      final repo = _CountingMembership();
      final c = fakeContainer(
        overrides: [membershipRepositoryProvider.overrideWith((ref) => repo)],
      );
      addTearDown(c.dispose);
      final sub = c.listen(membershipProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(membershipProvider.future);
      await repo.requestToJoin('c2'); // made elsewhere; state still says none
      final before = repo.reads;
      await expectLater(
        c.read(membershipProvider.notifier).requestToJoin('c1'),
        throwsA(isA<MembershipLimitReached>()),
      );
      await c.read(membershipProvider.future);
      expect(repo.reads, greaterThan(before));
      expect(c.read(membershipProvider).value?.communityId, 'c2');
    });
  });
}
