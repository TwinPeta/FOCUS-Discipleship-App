import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/auth/data/remote_auth_repository.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/auth/domain/otp_verifier.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _session({String id = 'u1'}) => {
  'access_token': 'a1',
  'refresh_token': 'r1',
  'expires_in': 900,
  'user': {
    'id': id,
    'full_name': 'Grace Namuli',
    'username': 'gracen',
    'email': 'grace@fcu.test',
    'birthdate': '2003-05-12',
    'country': 'UG',
    'institution': {
      'id': 'i1',
      'name': 'Makerere University',
      'type': 'university',
      'country': 'UG',
    },
  },
};

void main() {
  group('ApiClient', () {
    test('sends the bearer token and a JSON body', () async {
      late http.Request seen;
      final api = ApiClient(
        baseUrl: 'https://api.test/v1/',
        client: MockClient((request) async {
          seen = request;
          return _json(200, {'ok': true});
        }),
      )..tokens.save(access: 'tok', refresh: 'ref');

      final out = await api.post('/things', body: {'a': 1});

      expect(out, {'ok': true});
      expect(seen.url.toString(), 'https://api.test/v1/things');
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(seen.body), {'a': 1});
    });

    test('refreshes once on 401 and retries the call', () async {
      var calls = 0;
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return _json(200, {
              'access_token': 'new-a',
              'refresh_token': 'new-r',
            });
          }
          calls++;
          return request.headers['Authorization'] == 'Bearer new-a'
              ? _json(200, {'me': true})
              : _json(401, {'code': 'unauthorized'});
        }),
      )..tokens.save(access: 'old-a', refresh: 'old-r');

      expect(await api.get('/me'), {'me': true});
      expect(calls, 2);
      expect(api.tokens.refreshToken, 'new-r');
    });

    test('a failed refresh clears the session and surfaces the 401', () async {
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        client: MockClient((request) async => _json(401, {'code': 'x'})),
      )..tokens.save(access: 'a', refresh: 'r');

      await expectLater(
        api.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
      expect(api.tokens.hasSession, isFalse);
    });

    test('maps problem+json field errors', () async {
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        client: MockClient(
          (_) async => _json(422, {
            'code': 'validation_failed',
            'errors': [
              {'field': 'username', 'message': 'is taken'},
            ],
          }),
        ),
      );
      await expectLater(
        api.post('/auth/register', auth: false, body: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 422)
              .having((e) => e.fieldErrors['username'], 'field', 'is taken'),
        ),
      );
    });

    test('an unreachable server is status 0', () async {
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        api.get('/me'),
        throwsA(
          isA<ApiException>().having((e) => e.isNetwork, 'network', true),
        ),
      );
    });
  });

  group('RemoteAuthRepository', () {
    RemoteAuthRepository repo(MockClientHandler handler) =>
        RemoteAuthRepository(
          ApiClient(
            baseUrl: 'https://api.test/v1',
            client: MockClient(handler),
          ),
        );

    test('signIn stores tokens and returns the account', () async {
      final auth = repo((request) async {
        expect(request.url.path, '/v1/auth/login');
        expect(jsonDecode(request.body)['identifier'], 'grace@fcu.test');
        return _json(200, _session());
      });
      final session = await auth.signIn('grace@fcu.test', 'Password1234');
      expect(session.accountId, 'u1');
      expect(session.email, 'grace@fcu.test');
    });

    test('isEmailAvailable asks the API and reads the answer', () async {
      final taken = repo((request) async {
        expect(request.url.path, '/v1/auth/email-available');
        expect(request.url.queryParameters['email'], 'grace@fcu.test');
        return _json(200, {'available': false});
      });
      expect(await taken.isEmailAvailable(' Grace@FCU.test '), isFalse);
      final free = repo((_) async => _json(200, {'available': true}));
      expect(await free.isEmailAvailable('new@fcu.test'), isTrue);
    });

    test('isEmailAvailable lets the step go on when the check fails', () async {
      final limited = repo((_) async => _json(429, {'code': 'rate_limited'}));
      expect(await limited.isEmailAvailable('a@fcu.test'), isTrue);
    });

    test('signIn turns a 401 into InvalidCredentials', () async {
      final auth = repo((_) async => _json(401, {'code': 'unauthorized'}));
      await expectLater(
        auth.signIn('grace@fcu.test', 'wrong'),
        throwsA(isA<InvalidCredentials>()),
      );
    });

    test(
      'email code: wrong then verified; sign-up needs the email verified',
      () async {
        var verifyCalls = 0;
        final auth = repo((request) async {
          if (request.url.path.endsWith('/otp/verify')) {
            verifyCalls++;
            return verifyCalls == 1
                ? _json(400, {'code': 'otp_invalid'})
                : _json(204, null);
          }
          return _json(202, null);
        });
        final consent = Consent(
          charterAccepted: true,
          participationAccepted: true,
          nationalActivitiesAccepted: true,
          mentorContactAllowed: false,
          acceptedAt: DateTime(2026),
        );
        await expectLater(
          auth.createAccount(
            email: 'grace@fcu.test',
            passwordDigest: 'Password1234',
            consent: consent,
          ),
          throwsA(isA<SignUpIncomplete>()),
        );

        await auth.sendVerificationCode('grace@fcu.test');
        final wrong = await auth.verifyCode('grace@fcu.test', '111111');
        expect(wrong.status, OtpStatus.wrong);
        expect(wrong.attemptsLeft, OtpVerifier.maxAttempts - 1);
        final ok = await auth.verifyCode('grace@fcu.test', '123456');
        expect(ok.status, OtpStatus.verified);
        expect(await auth.isEmailVerified('Grace@fcu.test'), isTrue);

        final created = await auth.createAccount(
          email: 'grace@fcu.test',
          passwordDigest: 'Password1234',
          consent: consent,
        );
        expect(created.email, 'grace@fcu.test');
      },
    );
  });
}
