import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/profile/domain/user_profile.dart';
import 'package:focus_1/features/profile/presentation/widgets/profile_reminder.dart';

import '../support/pump_utils.dart';

void main() {
  group('missingProfileDetails', () {
    test('a complete profile needs nothing', () {
      expect(missingProfileDetails(testProfile), isEmpty);
    });

    test('lists a missing home church and year of study', () {
      final p = UserProfile(
        id: 'x',
        fullName: 'Grace Namuli',
        username: 'grace',
        birthdate: DateTime(2002),
        country: 'Uganda',
        email: 'g@fcu.test',
        phone: '+256700000000',
        institutionType: InstitutionType.university,
        institutionName: 'Makerere University',
      );
      expect(missingProfileDetails(p), [
        'Home church (name, location and pastor)',
        'Year of study',
      ]);
    });

    test('institute students are not asked for a year of study', () {
      final p = testProfile.copyWith(
        institutionType: InstitutionType.institute,
        clearYearOfStudy: true,
      );
      expect(missingProfileDetails(p), isEmpty);
    });
  });
}
