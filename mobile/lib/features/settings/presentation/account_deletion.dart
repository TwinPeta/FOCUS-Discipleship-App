import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../../profile/presentation/profile_providers.dart';

/// Deletes the signed-in account (screen 49), in order: check the password
/// and delete the account (throws `InvalidCredentials`, nothing else
/// changes), then the profile and membership, then the session. A backend
/// deletes posts and messages within the deletion window.
class AccountDeletion {
  AccountDeletion(this._ref);

  final Ref _ref;

  Future<void> delete(String password) async {
    final session = _ref.read(authSessionProvider);
    await _ref.read(authRepositoryProvider).deleteAccount(password);
    if (session != null) {
      await _ref
          .read(profileRepositoryProvider)
          .deleteProfile(session.accountId);
    }
    try {
      await _ref.read(membershipRepositoryProvider).clear();
    } catch (_) {
      // Leaving the community is best effort; the account is already gone.
    }
    await _ref.read(authControllerProvider.notifier).signOut();
    _ref
      ..invalidate(profileControllerProvider)
      ..invalidate(membershipProvider)
      ..invalidate(notificationsProvider);
  }
}

final accountDeletionProvider = Provider<AccountDeletion>(AccountDeletion.new);
