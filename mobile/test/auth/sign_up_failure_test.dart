import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/network/api_client.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/auth/presentation/sign_up_failure.dart';
import 'package:focus_1/features/profile/data/profile_repository.dart';

void main() {
  test('an email that already has an account points to Sign in', () {
    final f = describeSignUpFailure(
      const ProfileValidationError({'email': 'already used'}),
    );
    expect(f.fix, SignUpFix.signIn);
    expect(f.message, contains('already uses this email'));
  });

  test('a taken username names it and points to the details form', () {
    final f = describeSignUpFailure(const UsernameTakenError('grace'));
    expect(f.fix, SignUpFix.editDetails);
    expect(f.message, contains('@grace'));
  });

  test('a rejected detail says which one', () {
    final f = describeSignUpFailure(
      const ProfileValidationError({'yearOfStudy': 'must be 1-7'}),
    );
    expect(f.fix, SignUpFix.editDetails);
    expect(f.message, contains('year of study must be 1-7'));
  });

  test('a lost draft or unverified email starts again', () {
    expect(
      describeSignUpFailure(const SignUpIncomplete('email')).fix,
      SignUpFix.startAgain,
    );
    expect(
      describeSignUpFailure(StateError('Sign-up is incomplete')).fix,
      SignUpFix.startAgain,
    );
  });

  test('no connection, rate limit and server errors say so', () {
    expect(
      describeSignUpFailure(const ApiException(0)).message,
      contains('internet'),
    );
    expect(
      describeSignUpFailure(const ApiException(429)).message,
      contains('Too many tries'),
    );
    final server = describeSignUpFailure(
      const ApiException(500, message: 'Internal error'),
    );
    expect(server.message, contains('Internal error, 500'));
    expect(server.fix, SignUpFix.none);
  });
}
