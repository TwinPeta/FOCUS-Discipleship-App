import '../../moderation/data/moderation_queue_repository.dart';
import '../../moderation/domain/moderation_case.dart';
import '../domain/report.dart';

/// The single report path for every target type (users, conversations,
/// posts, comments, prayer requests, testimonies).
abstract class ReportRepository {
  Future<void> submitReport(Report report);
}

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({
    this.latency = const Duration(milliseconds: 400),
    this.moderation,
  });

  final Duration latency;

  /// Community content with a community id is also filed into this queue,
  /// so the community's super-mentor sees it on "Reports to review".
  final ModerationQueueRepository? moderation;
  final List<Report> _reports = [];

  /// Stored reports (for tests; a real backend owns this).
  List<Report> get reports => List.unmodifiable(_reports);

  @override
  Future<void> submitReport(Report report) async {
    await Future.delayed(latency);
    final queue = moderation;
    final moderated =
        ModeratedContent.fromReportTarget(report.targetType) != null &&
        (report.communityId ?? '').isNotEmpty;
    if (queue != null && moderated) await queue.fileReport(report);
    _reports.add(report);
  }
}
