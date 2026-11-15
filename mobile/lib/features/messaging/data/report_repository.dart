import '../domain/report.dart';

/// The single report path for every target type (users, conversations,
/// posts, comments, prayer requests, testimonies).
abstract class ReportRepository {
  Future<void> submitReport(Report report);
}
