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

/// The reset code is wrong, expired or used up (or the email has no
/// account: the same answer, so nobody can probe for accounts).
class InvalidResetCode implements Exception {
  const InvalidResetCode();
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

  /// Emails a 6-digit reset code. Always completes the same way, whether
  /// or not [email] has an account. Throws [ResendTooSoon] when asked again
  /// too soon.
  Future<void> requestPasswordReset(String email);

  /// Sets [password] with the emailed [code]; throws [InvalidResetCode].
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  });

  Future<GuardianRequest?> guardianRequest(String accountId);
  Future<GuardianRequest> submitGuardianRequest(
    String accountId,
    GuardianRequest request, {
    required String ownEmail,
  });

  /// Debug-only stand-in for the guardian clicking the emailed link.
  Future<GuardianRequest?> debugConfirmGuardian(String accountId);
}
