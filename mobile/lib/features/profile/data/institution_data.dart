/// Seeded, fake-but-realistic institution lists per country. These stand in
/// for a real institutions lookup until the backend exists.
class InstitutionData {
  InstitutionData._();

  static const List<String> countries = ['Uganda', 'Kenya', 'Rwanda'];

  static const Map<String, List<String>> universitiesByCountry = {
    'Uganda': [
      'Makerere University',
      'Kyambogo University',
      'Mbarara University of Science and Technology',
      'Uganda Christian University',
    ],
    'Kenya': [
      'University of Nairobi',
      'Kenyatta University',
      'Strathmore University',
      'Moi University',
    ],
    'Rwanda': [
      'University of Rwanda',
      'Mount Kenya University Rwanda',
      'University of Kigali',
      'Adventist University of Central Africa',
    ],
  };

  static const Map<String, List<String>> highSchoolsByCountry = {
    'Uganda': [
      "Gayaza High School",
      'Kings College Budo',
      'Namilyango College',
      "St. Mary's College Kisubi",
    ],
    'Kenya': [
      'Alliance High School',
      'Kenya High School',
      'Starehe Boys Centre',
      'Precious Blood Riruta',
    ],
    'Rwanda': [
      'Lycee de Kigali',
      'Green Hills Academy',
      'FAWE Girls School',
      'Riviera High School',
    ],
  };
}
