import '../../../core/utils/initials.dart';

enum InstitutionType { university, highSchool }

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
    );
  }

  String get initials => initialsOf(fullName);
}
