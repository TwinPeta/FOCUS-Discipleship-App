import '../../../core/utils/password_policy.dart';
import '../../../core/utils/validators.dart';
import '../domain/auth_models.dart';
import '../domain/otp_verifier.dart';

/// Thrown for any failed sign-in. Deliberately carries no detail about
/// whether the email or the password was wrong.
class InvalidCredentials implements Exception {
  const InvalidCredentials();
  @override
  String toString() => 'InvalidCredentials';
}

class EmailTakenError implements Exception {
  const EmailTakenError();
}

class ResendTooSoon implements Exception {
  const ResendTooSoon(this.wait);
  final Duration wait;
}

class SignUpIncomplete implements Exception {
  const SignUpIncomplete(this.reason);
  final String reason;
  @override
  String toString() => 'SignUpIncomplete($reason)';
}

class GuardianEmailInvalid implements Exception {
  const GuardianEmailInvalid(this.message);
  final String message;
}

abstract class AuthRepository {
  Future<AuthSession?> currentSession();

  /// Throws [InvalidCredentials] for an unknown email *or* a wrong password.
  Future<AuthSession> signIn(String email, String password);
  Future<void> signOut();

  /// Deletes the signed-in account after checking [password]; throws
  /// [InvalidCredentials] when it is wrong (nothing is deleted) and ends
  /// the session on success. Passwords are never logged.
  Future<void> deleteAccount(String password);

  Future<bool> isEmailAvailable(String email);

  /// Throws [ResendTooSoon] inside the 30s cooldown.
  Future<void> sendVerificationCode(String email);
  Future<OtpResult> verifyCode(String email, String code);
  Future<bool> isEmailVerified(String email);

  /// Creates the account and signs in. Requires a verified email, a valid
  /// password digest and a valid [Consent].
  Future<AuthSession> createAccount({
    required String email,
    required String passwordDigest,
    required Consent consent,
  });

  /// Always completes the same way, whether or not [email] has an account.
  Future<void> requestPasswordReset(String email);

  Future<GuardianRequest?> guardianRequest(String accountId);
  Future<GuardianRequest> submitGuardianRequest(
    String accountId,
    GuardianRequest request, {
    required String ownEmail,
  });

  /// Debug-only stand-in for the guardian clicking the emailed link.
  Future<GuardianRequest?> debugConfirmGuardian(String accountId);
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

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future.delayed(latency);
    // Only known emails actually get a link; the caller can't tell.
    if (_accounts.containsKey(_key(email))) resetRequests.add(_key(email));
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
