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
