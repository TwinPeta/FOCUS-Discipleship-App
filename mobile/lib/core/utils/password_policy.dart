/// Password rules for new accounts. Shared by the live checklist and the
/// repository, so the UI can never accept what the data layer rejects.
class PasswordPolicy {
  PasswordPolicy._();

  static const minLength = 10;

  static bool hasMinLength(String password) => password.length >= minLength;

  static bool hasLetterAndNumber(String password) =>
      RegExp(r'[A-Za-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password);

  static bool isValid(String password) =>
      hasMinLength(password) && hasLetterAndNumber(password);
}

/// FAKE password digest for the in-memory auth repository only: lets the
/// app avoid holding plain-text passwords in state. A real backend receives
/// the password over TLS and hashes it with a proper KDF server-side.
String fakePasswordDigest(String password, {String salt = 'fcu-fake-salt'}) {
  // FNV-1a 64-bit, iterated. Not cryptographic; never ship this as auth.
  const prime = 0x100000001b3;
  var hash = 0xcbf29ce484222325;
  for (var round = 0; round < 1000; round++) {
    for (final unit in '$salt:$round:$password'.codeUnits) {
      hash ^= unit;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
  }
  return hash.toRadixString(16);
}
