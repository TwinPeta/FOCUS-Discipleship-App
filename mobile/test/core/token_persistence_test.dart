import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/network/token_vault.dart';
import 'package:focus_1/features/auth/data/remote_auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _me() => {
  'id': 'u1',
  'email': 'grace@fcu.test',
  'full_name': 'Grace',
};

void main() {
  group('the sign-in survives closing the app', () {
    test('a saved session comes back, and sign-out forgets it', () async {
      final vault = MemoryTokenVault();
      final first = TokenStore(vault: vault);
      first.save(access: 'a1', refresh: 'r1');
      first.remember(accountId: 'u1', email: 'grace@fcu.test');
      await Future<void>.delayed(Duration.zero);

      // A new launch: a new store over the same storage.
      final second = TokenStore(vault: vault);
      expect(second.hasSession, isFalse);
      await second.restore();
      expect(second.hasSession, isTrue);
      expect(second.accessToken, 'a1');
      expect(second.refreshToken, 'r1');
      expect(second.accountId, 'u1');
      expect(second.email, 'grace@fcu.test');

      second.clear();
      await Future<void>.delayed(Duration.zero);
      expect(vault.saved, isNull);
      final third = TokenStore(vault: vault);
      await third.restore();
      expect(third.hasSession, isFalse);
    });

    test('a refreshed pair replaces the saved one', () async {
      final vault = MemoryTokenVault();
      final store = TokenStore(vault: vault)..save(access: 'a1', refresh: 'r1');
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        tokens: store,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return _json(200, {'access_token': 'a2', 'refresh_token': 'r2'});
          }
          return request.headers['Authorization'] == 'Bearer a2'
              ? _json(200, _me())
              : _json(401, {'code': 'unauthorized'});
        }),
      );
      await api.get('/me');
      await Future<void>.delayed(Duration.zero);
      expect(vault.saved?.refresh, 'r2');
    });

    test('a server error while renewing keeps the student signed in', () async {
      final store = TokenStore(vault: MemoryTokenVault())
        ..save(access: 'old', refresh: 'r1');
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        tokens: store,
        client: MockClient(
          (request) async => request.url.path.endsWith('/auth/refresh')
              ? _json(503, {'code': 'unavailable'})
              : _json(401, {'code': 'unauthorized'}),
        ),
      );
      expect(await api.refreshSession(), isFalse);
      expect(store.hasSession, isTrue);
    });

    test('a refused refresh token signs them out', () async {
      final store = TokenStore(vault: MemoryTokenVault())
        ..save(access: 'old', refresh: 'revoked');
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        tokens: store,
        client: MockClient((_) async => _json(401, {'code': 'unauthorized'})),
      );
      expect(await api.refreshSession(), isFalse);
      expect(store.hasSession, isFalse);
    });

    test('opening the app with no network keeps the saved session', () async {
      final store = TokenStore(vault: MemoryTokenVault())
        ..save(access: 'a1', refresh: 'r1')
        ..remember(accountId: 'u1', email: 'grace@fcu.test');
      final auth = RemoteAuthRepository(
        ApiClient(
          baseUrl: 'https://api.test/v1',
          tokens: store,
          client: MockClient((_) async => throw Exception('offline')),
        ),
      );
      final session = await auth.currentSession();
      expect(session?.accountId, 'u1');
      expect(session?.email, 'grace@fcu.test');
      expect(store.hasSession, isTrue);
    });

    test('a session the server refuses at launch is cleared', () async {
      final store = TokenStore(vault: MemoryTokenVault())
        ..save(access: 'a1', refresh: 'r1')
        ..remember(accountId: 'u1', email: 'grace@fcu.test');
      final auth = RemoteAuthRepository(
        ApiClient(
          baseUrl: 'https://api.test/v1',
          tokens: store,
          client: MockClient((_) async => _json(401, {'code': 'unauthorized'})),
        ),
      );
      expect(await auth.currentSession(), isNull);
      expect(store.hasSession, isFalse);
    });
  });
}
