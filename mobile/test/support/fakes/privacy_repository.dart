import 'package:focus_1/features/settings/data/privacy_repository.dart';

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
