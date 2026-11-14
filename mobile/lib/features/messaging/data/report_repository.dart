import '../domain/report.dart';

/// The single report path for every target type (users, conversations,
/// posts, comments, prayer requests).
abstract class ReportRepository {
  Future<void> submitReport(Report report);
}

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;
  final List<Report> _reports = [];

  /// Stored reports (for tests; a real backend owns this).
  List<Report> get reports => List.unmodifiable(_reports);

  @override
  Future<void> submitReport(Report report) async {
    await Future.delayed(latency);
    _reports.add(report);
  }
}
