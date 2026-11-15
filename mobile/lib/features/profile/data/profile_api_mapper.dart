import '../domain/user_profile.dart';

/// Country names the app shows <-> the API's ISO codes.
const _countryCodes = {'Uganda': 'UG', 'Kenya': 'KE', 'Rwanda': 'RW'};

String countryCodeOf(String name) => _countryCodes[name] ?? name;

String countryNameOf(String code) {
  for (final e in _countryCodes.entries) {
    if (e.value == code) return e.key;
  }
  return code;
}

String institutionTypeToApi(InstitutionType t) =>
    t == InstitutionType.university ? 'university' : 'high_school';

InstitutionType institutionTypeFromApi(String? t) => t == 'high_school'
    ? InstitutionType.highSchool
    : InstitutionType.university;

String dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// API `MyProfile` -> the app's [UserProfile]. The photo stays null for now:
/// the app model holds a local file path, not a URL.
UserProfile profileFromApi(Map<String, dynamic> j) {
  final institution = j['institution'];
  final inst = institution is Map<String, dynamic> ? institution : const {};
  return UserProfile(
    id: j['id'] as String,
    fullName: (j['full_name'] as String?) ?? '',
    username: (j['username'] as String?) ?? '',
    birthdate: DateTime.parse(j['birthdate'] as String),
    country: countryNameOf((j['country'] as String?) ?? ''),
    email: (j['email'] as String?) ?? '',
    phone: (j['phone'] as String?) ?? '',
    institutionType: institutionTypeFromApi(inst['type'] as String?),
    institutionName: (inst['name'] as String?) ?? '',
  );
}

/// API field name -> the join/edit form's field key.
const apiFieldToForm = {
  'full_name': 'fullName',
  'username': 'username',
  'birthdate': 'birthdate',
  'country': 'country',
  'email': 'email',
  'phone': 'phone',
  'institution_id': 'institutionName',
  'institution_type': 'institutionName',
};
