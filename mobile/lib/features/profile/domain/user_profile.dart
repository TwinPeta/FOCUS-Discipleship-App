import '../../../core/utils/initials.dart';

/// Where the student studies. New sign-ups pick a university or an
/// institute; [highSchool] remains only for accounts created before.
enum InstitutionType { university, institute, highSchool }

extension InstitutionTypeLabel on InstitutionType {
  String get label => switch (this) {
    InstitutionType.university => 'University',
    InstitutionType.institute => 'Institute',
    InstitutionType.highSchool => 'High school',
  };
}

/// The years of study a university student can pick.
const yearsOfStudy = [1, 2, 3, 4, 5, 6, 7];

/// The student's home church (all three are required at sign-up).
class HomeChurch {
  const HomeChurch({
    required this.name,
    required this.location,
    required this.pastor,
  });

  final String name;
  final String location;
  final String pastor;

  @override
  bool operator ==(Object other) =>
      other is HomeChurch &&
      other.name == name &&
      other.location == location &&
      other.pastor == pastor;

  @override
  int get hashCode => Object.hash(name, location, pastor);
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.birthdate,
    required this.country,
    required this.email,
    required this.phone,
    required this.institutionType,
    required this.institutionName,
    this.photoPath,
    this.yearOfStudy,
    this.homeChurch,
    this.showUsernameOnly = false,
  });

  final String id;
  final String fullName;
  final String username;
  final DateTime birthdate;
  final String country;
  final String email;
  final String phone;
  final InstitutionType institutionType;
  final String institutionName;
  final String? photoPath;

  /// University students only (1-7).
  final int? yearOfStudy;
  final HomeChurch? homeChurch;

  /// Other students see `@username` (no name, no photo) instead of this
  /// student's name. Staff still see who they are.
  final bool showUsernameOnly;

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? username,
    DateTime? birthdate,
    String? country,
    String? email,
    String? phone,
    InstitutionType? institutionType,
    String? institutionName,
    String? photoPath,
    int? yearOfStudy,
    HomeChurch? homeChurch,
    bool? showUsernameOnly,
    bool clearYearOfStudy = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      birthdate: birthdate ?? this.birthdate,
      country: country ?? this.country,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      institutionType: institutionType ?? this.institutionType,
      institutionName: institutionName ?? this.institutionName,
      photoPath: photoPath ?? this.photoPath,
      yearOfStudy: clearYearOfStudy ? null : (yearOfStudy ?? this.yearOfStudy),
      homeChurch: homeChurch ?? this.homeChurch,
      showUsernameOnly: showUsernameOnly ?? this.showUsernameOnly,
    );
  }

  String get initials => initialsOf(fullName);
}
