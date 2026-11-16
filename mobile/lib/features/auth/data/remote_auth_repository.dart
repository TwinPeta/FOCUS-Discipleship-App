import '../../../core/network/api_client.dart';
import '../../../core/utils/validators.dart';
import '../../profile/data/profile_api_mapper.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/auth_models.dart';
import '../domain/otp_verifier.dart';
import 'auth_repository.dart';

/// [AuthRepository] backed by the FCU API.
///
/// The app collects sign-up in steps (details -> verify email -> charter ->
/// password) but the API creates the account in one call. So [createAccount]
/// only checks and remembers the credentials; the account is actually created
/// by [register], which [RemoteProfileRepository.createProfile] calls with the
/// profile details. The "password digest" the sign-up draft hands over is the
/// password itself in this mode: it lives in memory until that call and is
/// never stored or logged.
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api);

  final ApiClient _api;

  final Set<String> _verified = {};
  final Map<String, int> _failures = {};
  final Map<String, DateTime> _lockedUntil = {};
  ({String email, String password, Consent consent})? _pending;
  String? _identifier;

  String _key(String email) => email.trim().toLowerCase();

  AuthSession _sessionFrom(Map<String, dynamic> user, String fallbackEmail) =>
      AuthSession(
        accountId: user['id'] as String,
        email: (user['email'] as String?) ?? fallbackEmail,
      );

  void _storeTokens(Map<String, dynamic> json) => _api.tokens.save(
    access: json['access_token'] as String,
    refresh: json['refresh_token'] as String,
  );

  @override
  Future<AuthSession?> currentSession() async {
    if (!_api.tokens.hasSession) return null;
    try {
      final me = await _api.get('/me') as Map<String, dynamic>;
      return _sessionFrom(me, '');
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        _api.tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthSession> signIn(String email, String password) async {
    try {
      final json = await _api.post(
        '/auth/login',
        auth: false,
        body: {'identifier': email.trim(), 'password': password},
      ) as Map<String, dynamic>;
      _storeTokens(json);
      _identifier = email.trim();
      return _sessionFrom(json['user'] as Map<String, dynamic>, _key(email));
    } on ApiException catch (e) {
      if (e.status == 401) throw const InvalidCredentials();
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    final refresh = _api.tokens.refreshToken;
    try {
      await _api.post(
        '/auth/logout',
        body: refresh == null ? null : {'refresh_token': refresh},
      );
    } on ApiException {
      // Offline or already expired: the local sign-out below still happens.
    } finally {
      _api.tokens.clear();
    }
  }

  @override
  Future<void> deleteAccount(String password) async {
    final id = _identifier;
    // The API's delete needs no password, so re-check it here first.
    if (id == null) throw const InvalidCredentials();
    try {
      await _api.post(
        '/auth/login',
        auth: false,
        body: {'identifier': id, 'password': password},
      );
    } on ApiException catch (e) {
      if (e.status == 401) throw const InvalidCredentials();
      rethrow;
    }
    await _api.delete('/me');
    _api.tokens.clear();
  }

  /// There is no pre-check endpoint: a duplicate email is reported by
  /// [register] (409) instead.
  @override
  Future<bool> isEmailAvailable(String email) async => true;

  @override
  Future<void> sendVerificationCode(String email) async {
    try {
      await _api.post(
        '/auth/otp/request',
        auth: false,
        body: {
          'channel': 'email',
          'destination': _key(email),
          'purpose': 'verify_contact',
        },
      );
    } on ApiException catch (e) {
      if (e.status == 429) {
        // Wait as long as the server says (60s if it does not say).
        throw ResendTooSoon(e.retryAfter ?? const Duration(seconds: 60));
      }
      rethrow;
    }
  }

  @override
  Future<OtpResult> verifyCode(String email, String code) async {
    final key = _key(email);
    final locked = _lockedUntil[key];
    if (locked != null && DateTime.now().isBefore(locked)) {
      return OtpResult.locked(locked);
    }
    try {
      await _api.post(
        '/auth/otp/verify',
        auth: false,
        body: {'destination': key, 'code': code, 'purpose': 'verify_contact'},
      );
      _verified.add(key);
      _failures.remove(key);
      return const OtpResult.verified();
    } on ApiException catch (e) {
      if (e.status == 400 || e.status == 422) {
        final failures = (_failures[key] ?? 0) + 1;
        _failures[key] = failures;
        if (failures >= OtpVerifier.maxAttempts) {
          _failures.remove(key);
          return OtpResult.locked(
            _lockedUntil[key] = DateTime.now().add(OtpVerifier.lockDuration),
          );
        }
        return OtpResult.wrong(OtpVerifier.maxAttempts - failures);
      }
      if (e.status == 429) {
        return OtpResult.locked(
          _lockedUntil[key] = DateTime.now().add(OtpVerifier.lockDuration),
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> isEmailVerified(String email) async =>
      _verified.contains(_key(email));

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String passwordDigest,
    required Consent consent,
  }) async {
    final key = _key(email);
    if (!consent.isValid) throw const SignUpIncomplete('consent');
    if (!_verified.contains(key)) throw const SignUpIncomplete('email');
    if (passwordDigest.isEmpty) throw const SignUpIncomplete('password');
    _pending = (email: key, password: passwordDigest, consent: consent);
    // Not a real account yet: the id is replaced when [register] runs.
    return AuthSession(accountId: 'pending', email: key);
  }

  /// Creates the account with the details collected during sign-up, signs
  /// in, and returns the profile the server stored.
  Future<UserProfile> register(
    UserProfile profile,
    String? institutionId,
  ) async {
    final pending = _pending;
    if (pending == null) throw const SignUpIncomplete('password');
    final json = await _api.post(
      '/auth/register',
      auth: false,
      body: {
        'full_name': profile.fullName.trim(),
        'username': profile.username.trim().toLowerCase(),
        'birthdate': dateOnly(profile.birthdate),
        'country': countryCodeOf(profile.country),
        'email': pending.email,
        if (profile.phone.trim().isNotEmpty) 'phone': profile.phone.trim(),
        'institution_type': institutionTypeToApi(profile.institutionType),
        if (institutionId != null)
          'institution_id': institutionId
        else
          // An institute that is not listed yet: the server adds it.
          'institution_name': profile.institutionName.trim(),
        if (profile.institutionType == InstitutionType.university)
          'year_of_study': profile.yearOfStudy,
        if (profile.homeChurch != null)
          'home_church': homeChurchToApi(profile.homeChurch!),
        'password': pending.password,
        'accepted_terms': pending.consent.participationAccepted,
        'accepted_code_of_conduct': pending.consent.charterAccepted,
        'accepted_national_activities':
            pending.consent.nationalActivitiesAccepted,
      },
    ) as Map<String, dynamic>;
    _storeTokens(json);
    _identifier = pending.email;
    _pending = null;
    return profileFromApi(json['user'] as Map<String, dynamic>);
  }

  /// Always completes the same way, whether or not [email] has an account.
  /// The API emails a code; there is not yet an endpoint to set a new
  /// password with it.
  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _api.post(
        '/auth/otp/request',
        auth: false,
        body: {
          'channel': 'email',
          'destination': _key(email),
          'purpose': 'password_reset',
        },
      );
    } on ApiException {
      // Same outcome for the user either way (no account enumeration).
    }
  }

  GuardianRequest? _guardianFrom(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final g = json['guardian'];
    if (g is! Map<String, dynamic>) return null;
    return GuardianRequest(
      guardianName: (g['name'] as String?) ?? '',
      guardianEmail: (g['email'] as String?) ?? (g['phone'] as String?) ?? '',
      relationship: (g['relationship'] as String?) ?? '',
      status: g['status'] == 'confirmed'
          ? GuardianStatus.confirmed
          : GuardianStatus.pending,
    );
  }

  @override
  Future<GuardianRequest?> guardianRequest(String accountId) async =>
      _guardianFrom(await _api.get('/me/guardian'));

  @override
  Future<GuardianRequest> submitGuardianRequest(
    String accountId,
    GuardianRequest request, {
    required String ownEmail,
  }) async {
    final formatError = Validators.email(request.guardianEmail);
    if (formatError != null) throw GuardianEmailInvalid(formatError);
    if (_key(request.guardianEmail) == _key(ownEmail)) {
      throw const GuardianEmailInvalid(
        "Use your guardian's email, not your own",
      );
    }
    try {
      final json = await _api.put(
        '/me/guardian',
        body: {
          'name': request.guardianName.trim(),
          'relationship': request.relationship,
          'email': request.guardianEmail.trim(),
        },
      );
      return _guardianFrom(json) ?? request;
    } on ApiException catch (e) {
      if (e.status == 422) {
        throw GuardianEmailInvalid(
          e.fieldErrors['email'] ?? e.message ?? 'Check the guardian details',
        );
      }
      rethrow;
    }
  }

  /// Debug-only in the fake. Here consent is confirmed by staff, so this
  /// just reports the current state.
  @override
  Future<GuardianRequest?> debugConfirmGuardian(String accountId) =>
      guardianRequest(accountId);
}
