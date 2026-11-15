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
