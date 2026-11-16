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

String institutionTypeToApi(InstitutionType t) => switch (t) {
  InstitutionType.university => 'university',
  InstitutionType.institute => 'institute',
  InstitutionType.highSchool => 'high_school',
};

InstitutionType institutionTypeFromApi(String? t) => switch (t) {
  'high_school' => InstitutionType.highSchool,
  'institute' => InstitutionType.institute,
  _ => InstitutionType.university,
};

Map<String, String> homeChurchToApi(HomeChurch c) => {
  'name': c.name.trim(),
  'location': c.location.trim(),
  'pastor': c.pastor.trim(),
};

HomeChurch? homeChurchFromApi(Object? j) {
  if (j is! Map<String, dynamic>) return null;
  return HomeChurch(
    name: (j['name'] as String?) ?? '',
    location: (j['location'] as String?) ?? '',
    pastor: (j['pastor'] as String?) ?? '',
  );
}

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
    yearOfStudy: (j['year_of_study'] as num?)?.toInt(),
    homeChurch: homeChurchFromApi(j['home_church']),
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
  'institution_name': 'institutionName',
  'year_of_study': 'yearOfStudy',
  'home_church': 'churchName',
  'home_church.name': 'churchName',
  'home_church.location': 'churchLocation',
  'home_church.pastor': 'churchPastor',
};
