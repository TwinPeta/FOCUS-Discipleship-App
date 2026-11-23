import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/core/router/route_guards.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/profile/domain/user_profile.dart';

import '../support/pump_utils.dart';

const _session = AuthSession(accountId: 'u1', email: 'grace@fcu.test');

GuardContext _ctx(
  String location, {
  required AsyncValue<UserProfile?> profile,
  AsyncValue<Membership> membership = const AsyncData(Membership.empty),
}) => GuardContext(
  location: Uri.parse(location),
  profile: profile,
  membership: membership,
  session: const AsyncData(_session),
);

void main() {
  const offline = ApiException(0, message: 'Could not reach the server');
  const failed = AsyncValue<UserProfile?>.error(offline, StackTrace.empty);

  group('signed in, profile could not load (offline)', () {
    test('is never sent to sign-up', () {
      for (final path in ['/communities', '/profile', '/messages']) {
        expect(runGuards(_ctx(path, profile: failed)), isNull, reason: path);
      }
    });

    test('the landing and sign-up pages send them to the hub', () {
      for (final path in ['/', '/join', '/join/start', '/login']) {
        expect(
          runGuards(_ctx(path, profile: failed)),
          '/communities',
          reason: path,
        );
      }
    });
  });

  test('a signed-in member on the landing page goes to the hub', () {
    final profile = AsyncData<UserProfile?>(testProfile);
    expect(runGuards(_ctx('/', profile: profile)), '/communities');
  });

  test('signed in with truly no profile still finishes sign-up', () {
    expect(
      runGuards(_ctx('/communities', profile: const AsyncData(null))),
      '/join',
    );
  });

  test('membership that could not load does not throw them out', () {
    final profile = AsyncData<UserProfile?>(testProfile);
    const error = AsyncValue<Membership>.error(offline, StackTrace.empty);
    expect(
      runGuards(
        _ctx(
          '/community/growth-circle/feed',
          profile: profile,
          membership: error,
        ),
      ),
      isNull,
    );
    expect(
      runGuards(
        _ctx(
          '/community/growth-circle/manage',
          profile: profile,
          membership: error,
        ),
      ),
      '/community/growth-circle/feed',
    );
  });
}
