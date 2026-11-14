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

/// What is being reported. One report model, one repository and one
/// `ReportFlow` serve every target.
enum ReportTargetType {
  user('user', 'user'),
  conversation('conversation', 'conversation'),
  post('post', 'post'),
  comment('comment', 'comment'),
  prayerRequest('prayer', 'prayer request'),
  testimony('testimony', 'testimony');

  const ReportTargetType(this.slug, this.noun);

  /// Used in report routes (`/report/:type/:id`).
  final String slug;

  /// Lower-case display noun ("prayer request").
  final String noun;

  static ReportTargetType? fromSlug(String slug) =>
      values.where((t) => t.slug == slug).firstOrNull;
}

class Report {
  const Report({
    required this.targetType,
    required this.targetId,
    this.targetUserId,
    required this.reason,
    this.details,
    this.screenshotPath,
  });

  final ReportTargetType targetType;

  /// Id of the reported item (thread id, post id…); the user id for
  /// [ReportTargetType.user].
  final String targetId;

  /// The person responsible for the reported content. Null for anonymous
  /// content (an anonymous prayer request): the client never knows that
  /// author, so moderation resolves it from [targetId].
  final String? targetUserId;

  /// Required: a report without a reason cannot be constructed.
  final ReportReason reason;
  final String? details;
  final String? screenshotPath;
}
