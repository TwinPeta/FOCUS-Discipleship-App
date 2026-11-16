import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/profile/domain/user_profile.dart';

/// Repeatedly pumps in small steps so chained fake-repository Futures (each
/// ~400ms) have time to resolve. A single long `pump(duration)` call isn't
/// reliable once providers depend on each other.
Future<void> settle(WidgetTester tester, {int steps = 10}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final testProfile = UserProfile(
  id: 'test-user',
  fullName: 'Grace Namuli',
  username: 'gracenamuli',
  birthdate: DateTime(2002, 1, 1),
  country: 'Uganda',
  email: 'grace@example.com',
  phone: '+256700000000',
  institutionType: InstitutionType.university,
  institutionName: 'Makerere University',
  yearOfStudy: 2,
  homeChurch: const HomeChurch(
    name: 'Watoto Church',
    location: 'Kampala',
    pastor: 'Pastor John',
  ),
);
