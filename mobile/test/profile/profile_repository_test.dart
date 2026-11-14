import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/profile/data/profile_repository.dart';

import '../support/pump_utils.dart';

void main() {
  FakeProfileRepository repo() =>
      FakeProfileRepository(latency: Duration.zero, seedDemoProfile: false);

  test('two concurrent creates produce one profile', () async {
    final r = repo();
    final results = await Future.wait([
      r.createProfile(testProfile),
      r.createProfile(testProfile.copyWith(id: 'other')),
    ]);
    expect(results[0], same(results[1]));
    expect((await r.getProfile(testProfile.id))!.id, testProfile.id);
  });

  test('a second profile for the same account is rejected', () async {
    final r = repo();
    await r.createProfile(testProfile);
    expect(
      () => r.createProfile(testProfile.copyWith(username: 'someone')),
      throwsA(isA<ProfileAlreadyExistsError>()),
    );
  });

  test('taken usernames are rejected case-insensitively', () async {
    final r = repo();
    expect(await r.isUsernameAvailable('DavidOkello'), isFalse);
    expect(
      () => r.createProfile(testProfile.copyWith(username: 'DAVIDOKELLO')),
      throwsA(isA<UsernameTakenError>()),
    );
  });

  test(
    'under-13 and malformed fields are rejected by the repository',
    () async {
      final r = repo();
      final now = DateTime.now();
      expect(
        () => r.createProfile(
          testProfile.copyWith(
            birthdate: DateTime(now.year - 12, now.month, now.day),
            email: 'nope',
          ),
        ),
        throwsA(
          isA<ProfileValidationError>().having(
            (e) => e.errors.keys,
            'fields',
            containsAll(['birthdate', 'email']),
          ),
        ),
      );
    },
  );

  test(
    'photo is optional and the own username stays available on update',
    () async {
      final r = repo();
      final saved = await r.createProfile(testProfile);
      expect(saved.photoPath, isNull);
      expect(
        await r.isUsernameAvailable(
          testProfile.username,
          ownerId: testProfile.id,
        ),
        isTrue,
      );
      expect(await r.isUsernameAvailable(testProfile.username), isFalse);
      final updated = await r.updateProfile(
        saved.copyWith(fullName: 'Grace N.'),
      );
      expect(updated.fullName, 'Grace N.');
    },
  );
}
