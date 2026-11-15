import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/features/community/data/remote_join_request_repository.dart';
import 'package:focus_1/features/community/domain/join_request.dart';
import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  RemoteJoinRequestRepository repo(http.Response Function() answer) {
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      client: MockClient((_) async => answer()),
    )..tokens.save(access: 'a', refresh: 'r');
    return RemoteJoinRequestRepository(api);
  }

  http.Response problem(int status, String code, String detail) =>
      http.Response(
        jsonEncode({'status': status, 'code': code, 'detail': detail}),
        status,
        headers: {'content-type': 'application/problem+json'},
      );

  test(
    'approving a student who is already in another community names it',
    () async {
      final r = repo(
        () => problem(
          409,
          'community_limit_reached',
          'This student already belongs to Life & Faith Circle',
        ),
      );
      await expectLater(
        r.approve('req1', actorRole: UserRole.superMentor),
        throwsA(
          isA<StudentAlreadyInCommunity>().having(
            (e) => e.communityName,
            'communityName',
            'Life & Faith Circle',
          ),
        ),
      );
    },
  );

  test('an already-decided request is reported as not pending', () async {
    final r = repo(
      () => problem(409, 'not_pending', 'This request was already decided'),
    );
    await expectLater(
      r.approve('req1', actorRole: UserRole.superMentor),
      throwsA(isA<JoinRequestNotPending>()),
    );
  });
}
