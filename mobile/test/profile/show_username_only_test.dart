import 'package:flutter_test/flutter_test.dart';
import 'package:focus_1/features/profile/data/profile_api_mapper.dart';

Map<String, dynamic> _json({Object? flag}) => {
  'id': 'u1',
  'full_name': 'Alice Namuli',
  'username': 'alice',
  'birthdate': '2003-04-05',
  'country': 'UG',
  'email': 'alice@example.com',
  'institution': {'type': 'university', 'name': 'Makerere University'},
  'show_username_only': ?flag,
};

void main() {
  test('the choice to show only the username is read from the profile', () {
    expect(profileFromApi(_json(flag: true)).showUsernameOnly, isTrue);
    expect(profileFromApi(_json(flag: false)).showUsernameOnly, isFalse);
  });

  test('an older server that does not send it means the name is shown', () {
    expect(profileFromApi(_json()).showUsernameOnly, isFalse);
  });

  test('copyWith changes only the choice', () {
    final p = profileFromApi(_json());
    final q = p.copyWith(showUsernameOnly: true);
    expect(q.showUsernameOnly, isTrue);
    expect(q.fullName, p.fullName);
    expect(q.username, p.username);
  });
}
