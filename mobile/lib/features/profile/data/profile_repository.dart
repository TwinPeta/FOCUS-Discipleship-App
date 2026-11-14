import '../../../core/utils/slug.dart';
import '../domain/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getCurrentProfile();
  Future<UserProfile> createProfile(UserProfile profile);
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Stable id derived from the profile's institution, used to look up its
  /// General community and to scope Specific communities.
  String institutionIdFor(UserProfile profile) =>
      slugify(profile.institutionName);
}

class FakeProfileRepository implements ProfileRepository {
  UserProfile? _profile;

  static const _latency = Duration(milliseconds: 400);

  @override
  Future<UserProfile?> getCurrentProfile() async {
    await Future.delayed(_latency);
    return _profile;
  }

  @override
  Future<UserProfile> createProfile(UserProfile profile) async {
    await Future.delayed(_latency);
    _profile = profile;
    return profile;
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await Future.delayed(_latency);
    _profile = profile;
    return profile;
  }

  @override
  String institutionIdFor(UserProfile profile) =>
      slugify(profile.institutionName);
}
