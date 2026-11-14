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

class Report {
  const Report({
    required this.targetUserId,
    required this.threadId,
    required this.reason,
    this.details,
    this.screenshotPath,
  });

  final String targetUserId;
  final String threadId;
  final ReportReason reason;
  final String? details;
  final String? screenshotPath;
}
