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
