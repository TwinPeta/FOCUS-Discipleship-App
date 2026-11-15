import '../domain/suspension.dart';

/// Account suspensions. Only admins set them (a backend concern); the app
/// only reads. The fake has a debug hook standing in for the admin tool.
abstract class SuspensionRepository {
  /// The account's suspension, or null. May return one that has already
  /// ended; callers check [Suspension.isActiveAt].
  Future<Suspension?> getSuspension(String accountId);
}
