import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/community/data/membership_repository.dart';
import 'package:focus_1/features/community/domain/membership.dart';

void main() {
  FakeMembershipRepository repo() =>
      FakeMembershipRepository(latency: Duration.zero);

  group('Membership.transitionTo', () {
    test('legal path none -> pending -> approved -> none', () {
      var m = Membership.empty.transitionTo(
        MembershipStatus.pending,
        communityId: 'c1',
      );
      expect(m.status, MembershipStatus.pending);
      expect(m.communityId, 'c1');
      m = m.transitionTo(MembershipStatus.approved);
      expect(m.communityId, 'c1');
      expect(m.transitionTo(MembershipStatus.none), same(Membership.empty));
    });

    test('pending -> rejected -> none is legal', () {
      final m = const Membership(
        communityId: 'c1',
        status: MembershipStatus.pending,
      ).transitionTo(MembershipStatus.rejected);
      expect(
        m.transitionTo(MembershipStatus.none).status,
        MembershipStatus.none,
      );
    });

    test('every other transition throws', () {
      const legal = {
        (MembershipStatus.none, MembershipStatus.pending),
        (MembershipStatus.pending, MembershipStatus.approved),
        (MembershipStatus.pending, MembershipStatus.rejected),
        (MembershipStatus.approved, MembershipStatus.none),
        (MembershipStatus.rejected, MembershipStatus.none),
      };
      for (final from in MembershipStatus.values) {
        for (final to in MembershipStatus.values) {
          if (legal.contains((from, to))) continue;
          final m = Membership(communityId: 'c1', status: from);
          expect(
            () => m.transitionTo(to, communityId: 'c1'),
            throwsA(isA<IllegalMembershipTransition>()),
            reason: '${from.name} -> ${to.name}',
          );
        }
      }
    });
  });

  group('FakeMembershipRepository', () {
    test('a second request for another community is rejected', () async {
      final r = repo();
      await r.requestToJoin('c1');
      expect(
        () => r.requestToJoin('c2'),
        throwsA(isA<MembershipLimitReached>()),
      );
    });

    test('a request while approved is rejected', () async {
      final r = repo();
      await r.requestToJoin('c1');
      await r.debugApprove();
      expect(
        () => r.requestToJoin('c1'),
        throwsA(isA<MembershipLimitReached>()),
      );
    });

    test('two rapid requests create one request', () async {
      final r = repo();
      final results = await Future.wait([
        r.requestToJoin('c1'),
        r.requestToJoin('c1'),
      ]);
      expect(
        results.map((m) => m.status),
        everyElement(MembershipStatus.pending),
      );
      expect((await r.getMembership()).communityId, 'c1');
    });

    test('approve or reject without a pending request throws', () async {
      final r = repo();
      expect(r.debugApprove, throwsA(isA<IllegalMembershipTransition>()));
      expect(r.reject, throwsA(isA<IllegalMembershipTransition>()));
    });

    test('after a rejection a new request is allowed', () async {
      final r = repo();
      await r.requestToJoin('c1');
      await r.reject();
      final m = await r.requestToJoin('c2');
      expect(m.communityId, 'c2');
      expect(m.status, MembershipStatus.pending);
    });
  });
}
