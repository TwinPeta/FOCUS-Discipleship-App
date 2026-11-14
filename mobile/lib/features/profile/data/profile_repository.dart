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

  /// Stable id derived from the profile's institution, used to look up its
  /// General community and to scope Specific communities.
  String institutionIdFor(UserProfile profile) =>
      slugify(profile.institutionName);
}

/// Shared by every [ProfileRepository]: the same rules the form shows inline.
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

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.latency = const Duration(milliseconds: 400),
    Set<String>? takenUsernames,
    bool seedDemoProfile = true,
  }) : _taken = takenUsernames ?? {'admin', 'fcu', 'davidokello'} {
    if (seedDemoProfile) {
      _profiles[demoProfile.id] = demoProfile;
      _taken.add(demoProfile.username);
    }
  }

  /// Profile of the debug demo account (`FakeAuthRepository.demoEmail`).
  static final demoProfile = UserProfile(
    id: 'demo-account',
    fullName: 'Demo Student',
    username: 'demostudent',
    birthdate: DateTime(2003, 5, 12),
    country: 'Uganda',
    email: 'demo@fcu.test',
    phone: '+256700000001',
    institutionType: InstitutionType.university,
    institutionName: 'Makerere University',
  );

  final Duration latency;
  final Set<String> _taken;
  final Map<String, UserProfile> _profiles = {};
  Future<UserProfile>? _inFlightCreate;

  @override
  Future<UserProfile?> getProfile(String accountId) async {
    await Future.delayed(latency);
    return _profiles[accountId];
  }

  bool _available(String username, String? ownerId) {
    final lower = username.trim().toLowerCase();
    final own = ownerId == null ? null : _profiles[ownerId];
    if (own != null && own.username.toLowerCase() == lower) return true;
    return !_taken.contains(lower);
  }

  @override
  Future<bool> isUsernameAvailable(String username, {String? ownerId}) async {
    await Future.delayed(latency);
    return _available(username, ownerId);
  }

  void _validate(UserProfile profile) {
    final errors = validateProfile(profile);
    if (errors.isNotEmpty) throw ProfileValidationError(errors);
    if (!_available(profile.username, profile.id)) {
      throw UsernameTakenError(profile.username);
    }
  }

  @override
  Future<UserProfile> createProfile(UserProfile profile) {
    return _inFlightCreate ??= _create(profile)
        .whenComplete(() => _inFlightCreate = null);
  }

  Future<UserProfile> _create(UserProfile profile) async {
    await Future.delayed(latency);
    if (_profiles.containsKey(profile.id)) {
      throw const ProfileAlreadyExistsError();
    }
    _validate(profile);
    _profiles[profile.id] = profile;
    _taken.add(profile.username.toLowerCase());
    return profile;
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await Future.delayed(latency);
    _validate(profile);
    final previous = _profiles[profile.id];
    if (previous != null) _taken.remove(previous.username.toLowerCase());
    _profiles[profile.id] = profile;
    _taken.add(profile.username.toLowerCase());
    return profile;
  }

  @override
  String institutionIdFor(UserProfile profile) =>
      slugify(profile.institutionName);
}
