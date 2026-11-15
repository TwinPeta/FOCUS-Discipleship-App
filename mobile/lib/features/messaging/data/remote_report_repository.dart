import '../../../core/network/api_client.dart';
import '../../../core/network/media_uploader.dart';
import '../domain/report.dart';
import 'report_repository.dart';

/// [ReportRepository] backed by the FCU API. Reports go to the admin team's
/// queue; the screenshot (if any) is uploaded first as evidence.
class RemoteReportRepository implements ReportRepository {
  RemoteReportRepository(this._api, this._uploader);

  final ApiClient _api;
  final MediaUploader _uploader;

  static String _reason(ReportReason r) => switch (r) {
    ReportReason.harassment => 'harassment_bullying',
    ReportReason.offensiveContent => 'offensive_content',
    ReportReason.breakingRules => 'breaks_community_rules',
    ReportReason.spamOrFakeProfile => 'spam_or_fake_profile',
    ReportReason.somethingElse => 'other',
  };

  @override
  Future<void> submitReport(Report report) async {
    String type;
    String id = report.targetId;
    var details = report.details?.trim() ?? '';
    switch (report.targetType) {
      case ReportTargetType.user:
        type = 'user';
      case ReportTargetType.conversation:
        // The API reports people, not whole conversations.
        final other = report.targetUserId;
        if (other == null) {
          throw ArgumentError('A conversation report needs the other person');
        }
        type = 'user';
        id = other;
        details = 'Reported from a conversation. $details'.trim();
      case ReportTargetType.post:
        type = 'post';
      case ReportTargetType.comment:
        type = 'comment';
      case ReportTargetType.prayerRequest:
        type = 'prayer_request';
      case ReportTargetType.testimony:
        type = 'testimony';
    }
    final shot = report.screenshotPath;
    final evidence = shot == null
        ? null
        : await _uploader.uploadPhoto(shot, purpose: 'report_evidence');
    await _api.post(
      '/reports',
      headers: {
        'Idempotency-Key':
            '$type-$id-${report.reporterId ?? ''}-${DateTime.now().microsecondsSinceEpoch}',
      },
      body: {
        'target_type': type,
        'target_id': id,
        'reason': _reason(report.reason),
        if (details.isNotEmpty) 'details': details,
        'evidence_media_id': ?evidence,
      },
    );
  }
}
