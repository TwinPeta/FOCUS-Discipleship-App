/// How long data is kept after the last activity (Privacy & data, 48).
const dataRetentionMonths = 24;

/// How long account deletion takes to complete (Delete account, 49).
const deletionWindowDays = 30;

/// Personal data requests. A backend builds the export and emails it.
abstract class PrivacyRepository {
  /// Queues a copy of the account's data to be emailed. Idempotent while a
  /// request is pending.
  Future<void> requestDataExport(String accountId);
}

class FakePrivacyRepository implements PrivacyRepository {
  FakePrivacyRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  /// Accounts with a pending export (for tests; a backend owns this).
  final Set<String> exportRequests = {};

  @override
  Future<void> requestDataExport(String accountId) async {
    await Future.delayed(latency);
    exportRequests.add(accountId);
  }
}
