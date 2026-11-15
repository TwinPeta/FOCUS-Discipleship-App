import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/safeguarding.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/auth_models.dart';

/// The in-memory session (no secure storage yet, by decision).
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() =>
      ref.watch(authRepositoryProvider).currentSession();

  /// Throws `InvalidCredentials` (generic) on failure.
  Future<void> signIn(String email, String password) async {
    final session = await ref
        .read(authRepositoryProvider)
        .signIn(email, password);
    state = AsyncValue.data(session);
  }

  Future<void> signOut() async {
    // While the tokens are still valid, so the DELETE /devices is signed.
    await ref.read(deviceRegistrationProvider)?.unregister();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }

  void setSession(AuthSession session) => state = AsyncValue.data(session);
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// Null while loading or signed out.
final authSessionProvider = Provider<AuthSession?>(
  (ref) => ref.watch(authControllerProvider).valueOrNull,
);

/// The guardian request of the signed-in account (minors only).
final guardianRequestProvider = FutureProvider<GuardianRequest?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return null;
  return ref.watch(authRepositoryProvider).guardianRequest(session.accountId);
});

/// True while the under-18 messaging limit applies to the current user.
/// Defaults to restricted until the guardian status is known (safe side).
final messagingRestrictedProvider = Provider<bool>((ref) {
  if (!kUnder18MessagingLimit) return false;
  final profile = ref.watch(currentProfileProvider);
  if (profile == null || !isMinor(profile)) return false;
  final guardian = ref.watch(guardianRequestProvider).valueOrNull;
  return guardian?.status != GuardianStatus.confirmed;
});

/// Holds sign-up answers across steps so Back never loses data. Stores a
/// password digest only.
class SignUpController extends Notifier<SignUpDraft> {
  @override
  SignUpDraft build() => SignUpDraft.empty;

  void setDetails(UserProfile details) =>
      state = state.copyWith(details: details);

  /// Throws [ArgumentError] if [password] breaks the policy.
  void setPassword(String password) {
    if (!PasswordPolicy.isValid(password)) {
      throw ArgumentError('Password does not meet the rules');
    }
    state = SignUpDraft(
      details: state.details,
      passwordDigest: ref.read(passwordSealProvider)(password),
    );
  }

  void markVerified() => state = state.copyWith(emailVerified: true);

  /// Creates the account and the profile, signs in, and clears the draft.
  /// Returns the created profile.
  Future<UserProfile> complete(Consent consent) async {
    final draft = state;
    final details = draft.details;
    if (details == null || draft.passwordDigest == null) {
      throw StateError('Sign-up is incomplete');
    }
    final session = await ref
        .read(authRepositoryProvider)
        .createAccount(
          email: details.email,
          passwordDigest: draft.passwordDigest!,
          consent: consent,
        );
    final profile = await ref
        .read(profileControllerProvider.notifier)
        .create(details.copyWith(id: session.accountId));
    // Profile first, then the session: the router sees a complete account.
    // With a real backend the account id only exists once the profile has
    // been created, so the session takes it from the profile.
    ref
        .read(authControllerProvider.notifier)
        .setSession(AuthSession(accountId: profile.id, email: session.email));
    state = SignUpDraft.empty;
    return profile;
  }

  void reset() => state = SignUpDraft.empty;
}

final signUpControllerProvider =
    NotifierProvider<SignUpController, SignUpDraft>(SignUpController.new);
