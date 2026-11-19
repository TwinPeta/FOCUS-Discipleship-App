import 'package:focus_1/features/moderation/data/suspension_repository.dart';
import 'package:focus_1/features/moderation/domain/suspension.dart';

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
