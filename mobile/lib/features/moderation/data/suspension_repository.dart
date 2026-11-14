import '../domain/suspension.dart';

/// Account suspensions. Only admins set them (a backend concern); the app
/// only reads. The fake has a debug hook standing in for the admin tool.
abstract class SuspensionRepository {
  /// The account's suspension, or null. May return one that has already
  /// ended; callers check [Suspension.isActiveAt].
  Future<Suspension?> getSuspension(String accountId);
}

class FakeSuspensionRepository implements SuspensionRepository {
  FakeSuspensionRepository({this.latency = const Duration(milliseconds: 200)});

  final Duration latency;
  final Map<String, Suspension> _byAccount = {};

  @override
  Future<Suspension?> getSuspension(String accountId) async {
    await Future.delayed(latency);
    return _byAccount[accountId];
  }

  /// Debug-only stand-in for the admin tool.
  void debugSuspend(String accountId, Suspension suspension) =>
      _byAccount[accountId] = suspension;

  void debugLift(String accountId) => _byAccount.remove(accountId);
}
