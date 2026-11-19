import '../../../core/utils/slug.dart';
import '../../../core/utils/validators.dart';
import '../domain/user_profile.dart';

class UsernameTakenError implements Exception {
  const UsernameTakenError(this.username);
  final String username;
  @override
  String toString() => 'UsernameTakenError($username)';
}

class ProfileAlreadyExistsError implements Exception {
  const ProfileAlreadyExistsError();
}

/// Field -> message, for rules the repository enforces itself.
class ProfileValidationError implements Exception {
  const ProfileValidationError(this.errors);
  final Map<String, String> errors;
  @override
  String toString() => 'ProfileValidationError($errors)';
}

/// Profiles are keyed by account id (`UserProfile.id == AuthSession.accountId`).
abstract class ProfileRepository {
  Future<UserProfile?> getProfile(String accountId);

  /// Case-insensitive; [ownerId]'s own username counts as available.
  Future<bool> isUsernameAvailable(String username, {String? ownerId});

  /// Validates every rule (formats, age >= 13, unique username). Concurrent
  /// calls share one request, and a second profile for the same account
  /// throws [ProfileAlreadyExistsError].
  Future<UserProfile> createProfile(UserProfile profile);
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Saves only the "show my username instead of my name" choice, so it
  /// cannot fail on the rest of the profile.
  Future<UserProfile> setShowUsernameOnly(UserProfile current, bool value);

  /// Removes the profile and frees its username. Idempotent.
  Future<void> deleteProfile(String accountId);

  /// Stable id derived from the profile's institution, used to look up its
  /// General community and to scope Specific communities.
  String institutionIdFor(UserProfile profile) =>
      slugify(profile.institutionName);
}

/// Shared by every [ProfileRepository]: the same rules the form shows inline.
/// Sign-up details beyond the basics: for university students the year of
/// study; the home church is optional (added later is fine) but, once any
/// part is given, needs all three fields.
Map<String, String> validateSignUpDetails(UserProfile p) {
  final church = p.homeChurch;
  final errors = <String, String?>{
    if (church != null) ...{
      'churchName': Validators.required(church.name, 'Church name'),
      'churchLocation': Validators.required(church.location, 'Church location'),
      'churchPastor': Validators.required(church.pastor, "Pastor's name"),
    },
    'yearOfStudy':
        p.institutionType == InstitutionType.university && p.yearOfStudy == null
        ? 'Year of study is required'
        : null,
  };
  return {
    for (final e in errors.entries)
      if (e.value != null) e.key: e.value!,
  };
}

Map<String, String> validateProfile(UserProfile p) {
  final errors = <String, String?>{
    'fullName': Validators.required(p.fullName, 'Full name'),
    'username': Validators.username(p.username),
    'birthdate': Validators.birthdate(p.birthdate),
    'country': Validators.required(p.country, 'Country'),
    'email': Validators.email(p.email),
    'phone': Validators.phone(p.phone),
    'institutionName': Validators.required(p.institutionName, 'Institution'),
  };
  return {
    for (final e in errors.entries)
      if (e.value != null) e.key: e.value!,
  };
}
