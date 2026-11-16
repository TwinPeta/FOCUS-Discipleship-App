import '../../profile/domain/user_profile.dart';

/// A signed-in account. Holds no secrets.
class AuthSession {
  const AuthSession({required this.accountId, required this.email});

  final String accountId;
  final String email;
}

class Account {
  const Account({required this.id, required this.email});

  final String id;
  final String email;
}

/// The charter consent given on "Before you join". Every required box must
/// be ticked explicitly; nothing is pre-ticked.
class Consent {
  const Consent({
    required this.charterAccepted,
    required this.participationAccepted,
    required this.nationalActivitiesAccepted,
    required this.mentorContactAllowed,
    required this.acceptedAt,
  });

  final bool charterAccepted;
  final bool participationAccepted;

  /// Agrees to take part in FOCUS national activities (required).
  final bool nationalActivitiesAccepted;
  final bool mentorContactAllowed;
  final DateTime acceptedAt;

  bool get isValid =>
      charterAccepted && participationAccepted && nationalActivitiesAccepted;
}

/// Everything collected across the sign-up steps. Holds a password
/// *digest*, never the password itself.
class SignUpDraft {
  const SignUpDraft({
    this.details,
    this.passwordDigest,
    this.emailVerified = false,
  });

  static const empty = SignUpDraft();

  /// The Join form's answers (its `id` is replaced by the account id).
  final UserProfile? details;
  final String? passwordDigest;
  final bool emailVerified;

  bool get hasDetails => details != null;
  bool get hasPassword => passwordDigest != null;

  SignUpDraft copyWith({
    UserProfile? details,
    String? passwordDigest,
    bool? emailVerified,
  }) => SignUpDraft(
    details: details ?? this.details,
    passwordDigest: passwordDigest ?? this.passwordDigest,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}

enum GuardianStatus { pending, confirmed }

class GuardianRequest {
  const GuardianRequest({
    required this.guardianName,
    required this.guardianEmail,
    required this.relationship,
    this.status = GuardianStatus.pending,
  });

  final String guardianName;
  final String guardianEmail;
  final String relationship;
  final GuardianStatus status;

  GuardianRequest copyWith({GuardianStatus? status}) => GuardianRequest(
    guardianName: guardianName,
    guardianEmail: guardianEmail,
    relationship: relationship,
    status: status ?? this.status,
  );
}

/// Age in whole years on [now].
int ageOn(DateTime birthdate, DateTime now) {
  final hadBirthday =
      now.month > birthdate.month ||
      (now.month == birthdate.month && now.day >= birthdate.day);
  return now.year - birthdate.year - (hadBirthday ? 0 : 1);
}

bool isMinor(UserProfile profile, {DateTime? now}) =>
    ageOn(profile.birthdate, now ?? DateTime.now()) < 18;
