import '../domain/report.dart';

abstract class ReportRepository {
  Future<void> submitReport(Report report);
}

class FakeReportRepository implements ReportRepository {
  static const _latency = Duration(milliseconds: 400);

  final List<Report> _reports = [];

  @override
  Future<void> submitReport(Report report) async {
    await Future.delayed(_latency);
    _reports.add(report);
  }
}
