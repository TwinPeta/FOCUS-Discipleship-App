enum ReportReason {
  harassment,
  offensiveContent,
  breakingRules,
  spamOrFakeProfile,
  somethingElse,
}

extension ReportReasonLabel on ReportReason {
  String get label => switch (this) {
    ReportReason.harassment => 'Harassment or bullying',
    ReportReason.offensiveContent => 'Offensive or inappropriate content',
    ReportReason.breakingRules => 'Breaking community rules',
    ReportReason.spamOrFakeProfile => 'Spam or fake profile',
    ReportReason.somethingElse => 'Something else',
  };
}

/// What is being reported. One report model and one repository serve
/// every target (prompt 2 adds posts and comments).
enum ReportTargetType { user, conversation, post, comment, prayerRequest }

class Report {
  const Report({
    required this.targetType,
    required this.targetId,
    required this.targetUserId,
    required this.reason,
    this.details,
    this.screenshotPath,
  });

  final ReportTargetType targetType;

  /// Id of the reported item (thread id, post id…); the user id for
  /// [ReportTargetType.user].
  final String targetId;

  /// The person responsible for the reported content.
  final String targetUserId;

  /// Required: a report without a reason cannot be constructed.
  final ReportReason reason;
  final String? details;
  final String? screenshotPath;
}
