import 'package:focus_1/features/profile/data/institution_repository.dart';
import 'package:focus_1/features/profile/domain/user_profile.dart';

class FakeInstitutionRepository implements InstitutionRepository {
  static const Map<String, List<String>> universities = {
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

  static const Map<String, List<String>> institutes = {
    'Uganda': [
      'Kampala Institute of Business and Technology',
      'Uganda Institute of Information and Communications Technology',
      'Nsamizi Training Institute of Social Development',
    ],
    'Kenya': [
      'Kenya Institute of Management',
      'Kenya Medical Training College',
      'Nairobi Technical Training Institute',
    ],
    'Rwanda': [
      'IPRC Kigali',
      'Rwanda Institute of Cooperatives',
      'Kigali Institute of Management',
    ],
  };

  static const Map<String, List<String>> highSchools = {
    'Uganda': [
      'Gayaza High School',
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

  @override
  Future<List<String>> names({
    required String country,
    required InstitutionType type,
  }) async {
    final byCountry = switch (type) {
      InstitutionType.university => universities,
      InstitutionType.institute => institutes,
      InstitutionType.highSchool => highSchools,
    };
    return byCountry[country] ?? const [];
  }
}
