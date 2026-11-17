import 'package:focus_1/core/utils/slug.dart';
import 'package:focus_1/features/profile/data/profile_repository.dart';
import 'package:focus_1/features/profile/domain/user_profile.dart';

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
  Future<void> deleteProfile(String accountId) async {
    await Future.delayed(latency);
    final removed = _profiles.remove(accountId);
    if (removed != null) _taken.remove(removed.username.toLowerCase());
  }

  @override
  String institutionIdFor(UserProfile profile) =>
      slugify(profile.institutionName);
}
