import '../../../core/network/api_client.dart';
import '../../../core/network/media_uploader.dart';
import '../../../core/widgets/sized_file_image.dart' show isPhotoUrl;
import '../../../core/utils/slug.dart';
import '../../auth/data/remote_auth_repository.dart';
import '../domain/user_profile.dart';
import 'profile_api_mapper.dart';
import 'profile_repository.dart';

/// [ProfileRepository] backed by the FCU API. Signing up creates the profile
/// and the account in one call, through [RemoteAuthRepository.register].
class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository(this._api, this._auth, this._uploader);

  final ApiClient _api;
  final RemoteAuthRepository _auth;
  final MediaUploader _uploader;

  /// A photo picked on this device (not yet on the server) is uploaded and
  /// its media id returned; a server photo, or none, needs nothing.
  Future<String?> _uploadPhoto(String? path) async {
    if (path == null ||
        path.isEmpty ||
        (isPhotoUrl(path) && !path.startsWith('blob:'))) {
      return null;
    }
    return _uploader.uploadPhoto(path, purpose: 'profile_photo');
  }

  UserProfile? _cached;
  Future<UserProfile>? _inFlightCreate;

  @override
  Future<UserProfile?> getProfile(String accountId) async {
    try {
      final me = await _api.get('/me') as Map<String, dynamic>;
      return _cached = profileFromApi(me);
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username, {String? ownerId}) async {
    final lower = username.trim().toLowerCase();
    final own = _cached;
    if (ownerId != null && own != null && own.username.toLowerCase() == lower) {
      return true;
    }
    try {
      final json = await _api.get(
        '/auth/username-available',
        query: {'username': lower},
      ) as Map<String, dynamic>;
      return json['available'] == true;
    } on ApiException catch (e) {
      if (e.status == 422) return false; // not a valid username
      rethrow;
    }
  }

  /// The API stores institutions by id; the app picks them by name. An
  /// institute the student typed because it is not listed has no id yet:
  /// null, and sign-up sends its name instead.
  Future<String?> _institutionId(UserProfile p) async {
    final json = await _api.get(
      '/lookups/institutions',
      query: {
        'type': institutionTypeToApi(p.institutionType),
        'country': countryCodeOf(p.country),
        'q': p.institutionName,
      },
    ) as Map<String, dynamic>;
    final items = (json['items'] as List).cast<Map<String, dynamic>>();
    final wanted = p.institutionName.trim().toLowerCase();
    for (final item in items) {
      if ((item['name'] as String).trim().toLowerCase() == wanted) {
        return item['id'] as String;
      }
    }
    if (p.institutionType == InstitutionType.institute) return null;
    throw const ProfileValidationError({
      'institutionName': 'We could not find this school yet. Pick another.',
    });
  }

  ProfileValidationError _fieldErrors(ApiException e) {
    final errors = <String, String>{};
    for (final entry in e.fieldErrors.entries) {
      errors[apiFieldToForm[entry.key] ?? entry.key] = entry.value;
    }
    return ProfileValidationError(
      errors.isEmpty ? {'fullName': e.message ?? 'Check your details'} : errors,
    );
  }

  @override
  Future<UserProfile> createProfile(UserProfile profile) {
    return _inFlightCreate ??= _create(profile)
        .whenComplete(() => _inFlightCreate = null);
  }

  Future<UserProfile> _create(UserProfile profile) async {
    final errors = {
      ...validateProfile(profile),
      ...validateSignUpDetails(profile),
    };
    if (errors.isNotEmpty) throw ProfileValidationError(errors);
    try {
      final institutionId = await _institutionId(profile);
      final created = await _auth.register(profile, institutionId);
      _cached = created;
      // The photo needs the new account's login to upload, so it follows
      // the sign-up. A failed upload never fails the sign-up.
      try {
        final mediaId = await _uploadPhoto(profile.photoPath);
        if (mediaId != null) {
          final json = await _api.patch(
            '/me',
            body: {'photo_media_id': mediaId},
          ) as Map<String, dynamic>;
          _cached = profileFromApi(json);
        }
      } catch (_) {}
      return _cached!;
    } on ApiException catch (e) {
      if (e.code == 'username_taken') {
        throw UsernameTakenError(profile.username);
      }
      if (e.code == 'email_taken') {
        throw const ProfileValidationError({
          'email': 'An account already uses this email. Sign in instead.',
        });
      }
      if (e.code == 'phone_taken') {
        throw const ProfileValidationError({
          'phone': 'An account already uses this phone number.',
        });
      }
      if (e.status == 422) throw _fieldErrors(e);
      rethrow;
    }
  }

  /// The API lets people change name, country, phone, email and institution.
  /// The username is fixed after sign-up, so a changed one is not sent.
  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final errors = validateProfile(profile);
    if (errors.isNotEmpty) throw ProfileValidationError(errors);
    try {
      final institutionId = await _institutionId(profile);
      final photoMediaId = await _uploadPhoto(profile.photoPath);
      final json = await _api.patch(
        '/me',
        body: {
          'photo_media_id': ?photoMediaId,
          'full_name': profile.fullName.trim(),
          'show_username_only': profile.showUsernameOnly,
          'country': countryCodeOf(profile.country),
          'email': profile.email.trim(),
          if (profile.phone.trim().isNotEmpty) 'phone': profile.phone.trim(),
          // An unlisted institute keeps the institution it was added as.
          'institution_id': ?institutionId,
          if (profile.institutionType == InstitutionType.university &&
              profile.yearOfStudy != null)
            'year_of_study': profile.yearOfStudy,
          if (profile.homeChurch != null)
            'home_church': homeChurchToApi(profile.homeChurch!),
        },
      ) as Map<String, dynamic>;
      return _cached = profileFromApi(json);
    } on ApiException catch (e) {
      if (e.code == 'email_taken') {
        throw const ProfileValidationError({
          'email': 'An account already uses this email.',
        });
      }
      if (e.code == 'phone_taken') {
        throw const ProfileValidationError({
          'phone': 'An account already uses this phone number.',
        });
      }
      if (e.status == 422) throw _fieldErrors(e);
      rethrow;
    }
  }

  @override
  Future<UserProfile> setShowUsernameOnly(
    UserProfile current,
    bool value,
  ) async {
    final json = await _api.patch(
      '/me',
      body: {'show_username_only': value},
    ) as Map<String, dynamic>;
    return _cached = profileFromApi(json);
  }

  /// Account deletion is done by [RemoteAuthRepository.deleteAccount].
  @override
  Future<void> deleteProfile(String accountId) async => _cached = null;

  @override
  String institutionIdFor(UserProfile profile) =>
      slugify(profile.institutionName);
}
