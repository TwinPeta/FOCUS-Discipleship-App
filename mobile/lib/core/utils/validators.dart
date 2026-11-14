/// Field validators for the Join form (section 6.2 of the brief). Each
/// returns an error message, or null when the value is valid.
class Validators {
  Validators._();

  static String? required(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel is required';
    }
    return null;
  }

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final requiredError = required(value, 'Email');
    if (requiredError != null) return requiredError;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static final _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

  static String? phone(String? value) {
    final requiredError = required(value, 'Phone number');
    if (requiredError != null) return requiredError;
    final digitsOnly = value!.trim().replaceAll(' ', '');
    if (!_phonePattern.hasMatch(digitsOnly)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static String? username(String? value) {
    final requiredError = required(value, 'Username');
    if (requiredError != null) return requiredError;
    if (!_usernamePattern.hasMatch(value!.trim())) {
      return '3-20 characters: letters, numbers and underscores only';
    }
    return null;
  }

  static String? birthdate(DateTime? value) {
    if (value == null) return 'Birthdate is required';
    final now = DateTime.now();
    final hasHadBirthdayThisYear =
        now.month > value.month ||
        (now.month == value.month && now.day >= value.day);
    final age = now.year - value.year - (hasHadBirthdayThisYear ? 0 : 1);
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    return null;
  }
}
