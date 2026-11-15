import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/core/connectivity/connectivity_service.dart';
import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/features/profile/data/institution_repository.dart';
import 'package:focus_1/features/profile/domain/user_profile.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiConnectivityService', () {
    test(
      'is online while the API answers and offline when it does not',
      () async {
        var up = true;
        final service = ApiConnectivityService(
          healthUrl: Uri.parse('https://api.test/v1/health'),
          client: MockClient((request) async {
            if (!up) throw http.ClientException('no route to host');
            return http.Response('{"status":"ok"}', 200);
          }),
          interval: const Duration(hours: 1),
        );
        addTearDown(service.dispose);

        final changes = <bool>[];
        service.onlineChanges.listen(changes.add);

        expect(service.isOnline, isTrue);
        expect(await service.check(), isTrue);

        up = false;
        expect(await service.check(), isFalse);
        expect(service.isOnline, isFalse);

        up = true;
        expect(await service.check(), isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(changes, [
          false,
          true,
        ], reason: 'only real changes are announced');
      },
    );

    test('a server error counts as offline', () async {
      final service = ApiConnectivityService(
        healthUrl: Uri.parse('https://api.test/v1/health'),
        client: MockClient((_) async => http.Response('', 503)),
        interval: const Duration(hours: 1),
      );
      addTearDown(service.dispose);
      expect(await service.check(), isFalse);
    });
  });

  group('RemoteInstitutionRepository', () {
    test('lists the server\'s schools for a country and type', () async {
      final seen = <Uri>[];
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        client: MockClient((request) async {
          seen.add(request.url);
          return http.Response(
            jsonEncode({
              'items': [
                {'id': 'i1', 'name': 'Makerere University'},
                {'id': 'i2', 'name': 'Kyambogo University'},
              ],
              'next_cursor': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final names = await RemoteInstitutionRepository(api)
          .names(country: 'Uganda', type: InstitutionType.university);

      expect(names, ['Makerere University', 'Kyambogo University']);
      expect(seen.single.path, '/v1/lookups/institutions');
      expect(seen.single.queryParameters['country'], 'UG');
      expect(seen.single.queryParameters['type'], 'university');
    });
  });
}
