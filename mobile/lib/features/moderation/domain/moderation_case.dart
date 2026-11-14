import '../../messaging/domain/report.dart';

/// What a super-mentor decided for a case (screen 32).
enum ModerationOutcome { hidden, warned, kept, escalated }

/// Kinds of content a community case can be about.
enum ModeratedContent {
  post('Post'),
  comment('Comment'),
  prayerRequest('Prayer request');

  const ModeratedContent(this.label);
  final String label;

  ReportTargetType get reportTarget => switch (this) {
    ModeratedContent.post => ReportTargetType.post,
    ModeratedContent.comment => ReportTargetType.comment,
    ModeratedContent.prayerRequest => ReportTargetType.prayerRequest,
  };
}

/// One reported item in a community, grouping every report against it.
/// Level 1 cases are handled by the community's super-mentor; escalated
/// cases go to the admin team.
class ModerationCase {
  const ModerationCase({
    required this.id,
    required this.communityId,
    required this.content,
    required this.targetId,
    required this.authorId,
    required this.authorName,
    required this.preview,
    required this.reason,
    required this.reportCount,
    required this.firstReporterName,
    required this.reportedAt,
    this.level = 1,
    this.outcome,
  });

  final String id;
  final String communityId;
  final ModeratedContent content;
  final String targetId;
  final String authorId;
  final String authorName;
  final String preview;

  /// The most common reason across the reports.
  final ReportReason reason;
  final int reportCount;
  final String firstReporterName;
  final DateTime reportedAt;
  final int level;
  final ModerationOutcome? outcome;

  bool get isOpen => outcome == null;

  ModerationCase copyWith({ModerationOutcome? outcome, int? level}) {
    return ModerationCase(
      id: id,
      communityId: communityId,
      content: content,
      targetId: targetId,
      authorId: authorId,
      authorName: authorName,
      preview: preview,
      reason: reason,
      reportCount: reportCount,
      firstReporterName: firstReporterName,
      reportedAt: reportedAt,
      level: level ?? this.level,
      outcome: outcome ?? this.outcome,
    );
  }
}

/// The case was already decided (or is being decided right now).
class ModerationCaseClosed implements Exception {
  const ModerationCaseClosed(this.id);
  final String id;
  @override
  String toString() => 'ModerationCaseClosed($id)';
}
