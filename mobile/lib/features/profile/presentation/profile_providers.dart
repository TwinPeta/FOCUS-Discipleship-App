import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/user_profile.dart';

/// The signed-in account's profile, loaded from and written through
/// [ProfileRepository] (the single source of truth). Null when signed out.
class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    // Stays loading until the session is known; rebuilds on sign-in/out.
    final session = await ref.watch(authControllerProvider.future);
    if (session == null) return null;
    return ref.watch(profileRepositoryProvider).getProfile(session.accountId);
  }

  Future<UserProfile> create(UserProfile profile) async {
    final saved = await ref
        .read(profileRepositoryProvider)
        .createProfile(profile);
    state = AsyncValue.data(saved);
    return saved;
  }

  Future<UserProfile> save(UserProfile profile) async {
    final saved = await ref
        .read(profileRepositoryProvider)
        .updateProfile(profile);
    state = AsyncValue.data(saved);
    return saved;
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(
      ProfileController.new,
    );

/// Convenience read of the loaded profile (null while loading or signed
/// out). Screens watch this; tests may override it directly.
final currentProfileProvider = Provider<UserProfile?>(
  (ref) => ref.watch(profileControllerProvider).valueOrNull,
);
