import '../../../core/network/api_client.dart';
import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';

/// Where the person should go to fix a failed sign-up.
enum SignUpFix { signIn, editDetails, startAgain, none }

/// What the last sign-up step (23, "Join my campus") tells the person when
/// creating the account fails: the real reason, and the screen that fixes it.
/// A plain "try again" hid every cause (email already registered, username
/// taken, a detail the server rejected), so retrying never helped.
({String message, SignUpFix fix}) describeSignUpFailure(Object error) {
  switch (error) {
    case UsernameTakenError(:final username):
      return (
        message: 'The username @$username is taken. Choose another one.',
        fix: SignUpFix.editDetails,
      );
    case ProfileValidationError(:final errors):
      final email = errors['email'];
      if (email != null) {
        return (
          message: 'An account already uses this email. Sign in, or reset '
              'your password if you forgot it.',
          fix: SignUpFix.signIn,
        );
      }
      final first = errors.entries.isEmpty ? null : errors.entries.first;
      return (
        message: first == null
            ? 'Some of your details need fixing.'
            : 'Check your details: ${_fieldLabel(first.key)} '
                  '${first.value}.',
        fix: SignUpFix.editDetails,
      );
    case SignUpIncomplete() || StateError():
      return (
        message: 'Your sign-up was interrupted. Please start again.',
        fix: SignUpFix.startAgain,
      );
    case ApiException(isNetwork: true):
      return (
        message: 'No connection to FCU. Check your internet and try again.',
        fix: SignUpFix.none,
      );
    case ApiException(status: 429):
      return (
        message: 'Too many tries. Wait a few minutes, then try again.',
        fix: SignUpFix.none,
      );
    case ApiException(:final status, :final message):
      return (
        message: 'We could not create your account '
            '(${message ?? 'server error'}, $status). Try again shortly.',
        fix: SignUpFix.none,
      );
    default:
      return (
        message: 'We could not create your account. Try again.',
        fix: SignUpFix.none,
      );
  }
}

String _fieldLabel(String formKey) => switch (formKey) {
  'fullName' => 'full name',
  'username' => 'username',
  'birthdate' => 'date of birth',
  'country' => 'country',
  'phone' => 'phone number',
  'institutionName' => 'school',
  'yearOfStudy' => 'year of study',
  'churchName' => 'church name',
  'churchLocation' => 'church location',
  'churchPastor' => 'pastor',
  _ => formKey.replaceAll('_', ' '),
};
