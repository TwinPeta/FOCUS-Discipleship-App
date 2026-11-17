import 'package:focus_1/core/utils/validators.dart';
import 'package:focus_1/features/auth/data/auth_repository.dart';
import 'package:focus_1/features/auth/domain/auth_models.dart';
import 'package:focus_1/features/auth/domain/otp_verifier.dart';

/// FAKE password digest for the in-memory auth repository only: lets the
/// app avoid holding plain-text passwords in state. A real backend receives
/// the password over TLS and hashes it with a proper KDF server-side.
String fakePasswordDigest(String password, {String salt = 'fcu-fake-salt'}) {
  // FNV-1a 32-bit, iterated. Not cryptographic; never ship this as auth.
  // 32-bit (not 64) and multiply-by-prime written as shifts so it gives the
  // same result on web (JavaScript numbers) as on Android and iOS.
  const mask = 0xFFFFFFFF;
  var hash = 0x811c9dc5;
  for (var round = 0; round < 1000; round++) {
    for (final unit in '$salt:$round:$password'.codeUnits) {
      hash = (hash ^ unit) & mask;
      // hash * 16777619 (FNV prime 0x01000193), modulo 2^32.
      hash =
          (hash +
              ((hash << 1) & mask) +
              ((hash << 4) & mask) +
              ((hash << 7) & mask) +
              ((hash << 8) & mask) +
              ((hash << 24) & mask)) &
          mask;
    }
  }
  return hash.toRadixString(16);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.latency = const Duration(milliseconds: 400),
    DateTime Function()? clock,
    bool seedDemoAccount = true,
  }) : _clock = clock ?? DateTime.now {
    if (seedDemoAccount) {
      debugSeedAccount(demoEmail, demoPassword, demoAccountId);
    }
  }

  /// Debug test account (also seeded with a profile).
  static const demoEmail = 'demo@fcu.test';
  static const demoPassword = 'Password1234';
  static const demoAccountId = 'demo-account';

  /// The fake always issues this code (shown on screen in debug builds).
  static const fakeCode = '123456';

  final Duration latency;
  final DateTime Function() _clock;

  final Map<String, ({String id, String digest})> _accounts = {};
  final Map<String, OtpVerifier> _otp = {};
  final Set<String> _verified = {};
  final Map<String, GuardianRequest> _guardians = {};
  final List<String> resetRequests = [];
  final Map<String, Consent> consents = {};
  AuthSession? _session;

  String _key(String email) => email.trim().toLowerCase();

  void debugSeedAccount(String email, String password, String accountId) {
    _accounts[_key(email)] = (
      id: accountId,
      digest: fakePasswordDigest(password),
    );
  }

  /// For tests: start signed in.
  void debugSignInAs(String email) {
    final account = _accounts[_key(email)]!;
    _session = AuthSession(accountId: account.id, email: _key(email));
  }

  @override
  Future<AuthSession?> currentSession() async {
    await Future.delayed(latency);
    return _session;
  }

  @override
  Future<AuthSession> signIn(String email, String password) async {
    await Future.delayed(latency);
    final account = _accounts[_key(email)];
    if (account == null || account.digest != fakePasswordDigest(password)) {
      throw const InvalidCredentials();
    }
    return _session = AuthSession(accountId: account.id, email: _key(email));
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(latency);
    _session = null;
  }

  @override
  Future<void> deleteAccount(String password) async {
    await Future.delayed(latency);
    final session = _session;
    if (session == null) throw const InvalidCredentials();
    final key = _key(session.email);
    final account = _accounts[key];
    if (account == null || account.digest != fakePasswordDigest(password)) {
      throw const InvalidCredentials();
    }
    _accounts.remove(key);
    _verified.remove(key);
    _guardians.remove(account.id);
    consents.remove(account.id);
    _session = null;
  }

  @override
  Future<bool> isEmailAvailable(String email) async {
    await Future.delayed(latency);
    return !_accounts.containsKey(_key(email));
  }

  OtpVerifier _verifierFor(String email) =>
      _otp.putIfAbsent(_key(email), () => OtpVerifier(clock: _clock));

  @override
  Future<void> sendVerificationCode(String email) async {
    await Future.delayed(latency);
    final verifier = _verifierFor(email);
    final wait = verifier.resendAvailableIn;
    if (wait != null) throw ResendTooSoon(wait);
    verifier.issue(fakeCode);
  }

  @override
  Future<OtpResult> verifyCode(String email, String code) async {
    await Future.delayed(latency);
    final result = _verifierFor(email).verify(code);
    if (result.status == OtpStatus.verified) _verified.add(_key(email));
    return result;
  }

  @override
  Future<bool> isEmailVerified(String email) async {
    await Future.delayed(latency);
    return _verified.contains(_key(email));
  }

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String passwordDigest,
    required Consent consent,
  }) async {
    await Future.delayed(latency);
    final key = _key(email);
    if (!consent.isValid) throw const SignUpIncomplete('consent');
    if (!_verified.contains(key)) throw const SignUpIncomplete('email');
    if (passwordDigest.isEmpty) throw const SignUpIncomplete('password');
    if (_accounts.containsKey(key)) throw const EmailTakenError();
    final id = 'acct-${DateTime.now().microsecondsSinceEpoch}';
    _accounts[key] = (id: id, digest: passwordDigest);
    consents[id] = consent;
    return _session = AuthSession(accountId: id, email: key);
  }

  /// The code the fake "emails" for every password reset.
  static const resetCode = '246810';

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future.delayed(latency);
    // Only known emails actually get a code; the caller can't tell.
    if (_accounts.containsKey(_key(email))) resetRequests.add(_key(email));
  }

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    await Future.delayed(latency);
    final key = _key(email);
    final account = _accounts[key];
    // A code works once, and only for the email it was sent to.
    if (account == null || code != resetCode || !resetRequests.remove(key)) {
      throw const InvalidResetCode();
    }
    _accounts[key] = (id: account.id, digest: fakePasswordDigest(newPassword));
  }

  @override
  Future<GuardianRequest?> guardianRequest(String accountId) async {
    await Future.delayed(latency);
    return _guardians[accountId];
  }

  @override
  Future<GuardianRequest> submitGuardianRequest(
    String accountId,
    GuardianRequest request, {
    required String ownEmail,
  }) async {
    await Future.delayed(latency);
    final formatError = Validators.email(request.guardianEmail);
    if (formatError != null) throw GuardianEmailInvalid(formatError);
    if (_key(request.guardianEmail) == _key(ownEmail)) {
      throw const GuardianEmailInvalid(
        "Use your guardian's email, not your own",
      );
    }
    final stored = request.copyWith(status: GuardianStatus.pending);
    _guardians[accountId] = stored;
    return stored;
  }

  @override
  Future<GuardianRequest?> debugConfirmGuardian(String accountId) async {
    await Future.delayed(latency);
    final current = _guardians[accountId];
    if (current == null) return null;
    return _guardians[accountId] = current.copyWith(
      status: GuardianStatus.confirmed,
    );
  }
}
