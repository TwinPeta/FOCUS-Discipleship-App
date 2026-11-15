import 'package:focus_1/features/community/domain/user_role.dart';
import 'package:focus_1/features/messaging/domain/report.dart';
import 'package:focus_1/features/moderation/data/moderation_queue_repository.dart';
import 'package:focus_1/features/moderation/data/warning_repository.dart';
import 'package:focus_1/features/moderation/domain/moderation_case.dart';
import 'package:focus_1/features/notifications/data/notification_repository.dart';
import 'package:focus_1/features/notifications/domain/app_notification.dart';

class FakeModerationQueueRepository implements ModerationQueueRepository {
  FakeModerationQueueRepository({
    this.latency = const Duration(milliseconds: 400),
    this.notifications,
    required this.warnings,
    List<ModerationCase>? seed,
  }) : _cases = [...(seed ?? _seed())];

  final Duration latency;
  final NotificationRepository? notifications;
  final WarningRepository warnings;
  final List<ModerationCase> _cases;
  final Set<String> _hidden = {};
  final Set<String> _inFlight = {};

  /// Per case: who reported it and how often each reason was given.
  final Map<String, Set<String>> _reporters = {};
  final Map<String, Map<ReportReason, int>> _reasonCounts = {};
  final Map<String, Future<ModerationCase>> _filing = {};
  int _filedCount = 0;

  static List<ModerationCase> _seed() {
    final now = DateTime.now();
    const c = 'growth-circle';
    return [
      ModerationCase(
        id: 'case-1',
        communityId: c,
        content: ModeratedContent.comment,
        targetId: '$c-comment-1',
        authorId: 'member-4',
        authorName: 'Isaac Wandera',
        preview:
            'This group is a waste of time, nobody here takes anything '
            'seriously.',
        reason: ReportReason.harassment,
        reportCount: 3,
        firstReporterName: 'Aisha Nakato',
        reportedAt: now.subtract(const Duration(days: 2)),
      ),
      ModerationCase(
        id: 'case-2',
        communityId: c,
        content: ModeratedContent.post,
        targetId: '$c-post-3',
        authorId: 'member-1',
        authorName: 'Faith Nabirye',
        preview:
            'Please keep my family in your prayers this week, my dad is not '
            'feeling well.',
        reason: ReportReason.breakingRules,
        reportCount: 2,
        firstReporterName: 'Brian Mugisha',
        reportedAt: now.subtract(const Duration(days: 1)),
      ),
      ModerationCase(
        id: 'case-3',
        communityId: c,
        content: ModeratedContent.prayerRequest,
        targetId: '$c-prayer-3',
        authorId: 'member-1',
        authorName: 'Faith Nabirye',
        preview:
            "Thankful for how my exams went. Praying for my family's health "
            'now.',
        reason: ReportReason.somethingElse,
        reportCount: 1,
        firstReporterName: 'Joy Atim',
        reportedAt: now,
      ),
    ];
  }

  void _requireSuperMentor(UserRole? role, String communityId) {
    if (role != UserRole.superMentor) throw NotSuperMentor(communityId);
  }

  @override
  Future<List<ModerationCase>> getOpenCases(
    String communityId, {
    required UserRole? actorRole,
  }) async {
    await Future.delayed(latency);
    _requireSuperMentor(actorRole, communityId);
    final open =
        _cases.where((x) => x.communityId == communityId && x.isOpen).toList()
          ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
    return List.unmodifiable(open);
  }

  @override
  Future<ModerationCase> hide(String caseId, {required UserRole? actorRole}) =>
      _decide(caseId, actorRole, ModerationOutcome.hidden);

  @override
  Future<ModerationCase> warnAuthor(
    String caseId, {
    required UserRole? actorRole,
  }) => _decide(caseId, actorRole, ModerationOutcome.warned);

  @override
  Future<ModerationCase> keep(String caseId, {required UserRole? actorRole}) =>
      _decide(caseId, actorRole, ModerationOutcome.kept);

  @override
  Future<ModerationCase> escalate(
    String caseId, {
    required UserRole? actorRole,
  }) => _decide(caseId, actorRole, ModerationOutcome.escalated);

  Future<ModerationCase> _decide(
    String caseId,
    UserRole? actorRole,
    ModerationOutcome outcome,
  ) async {
    if (!_inFlight.add(caseId)) throw ModerationCaseClosed(caseId);
    try {
      await Future.delayed(latency);
      final i = _cases.indexWhere((x) => x.id == caseId);
      if (i == -1) throw ArgumentError.value(caseId, 'caseId', 'unknown case');
      final current = _cases[i];
      _requireSuperMentor(actorRole, current.communityId);
      if (!current.isOpen) throw ModerationCaseClosed(caseId);
      if (outcome == ModerationOutcome.warned && !current.canWarn) {
        throw ModerationAuthorUnknown(caseId);
      }
      final authorId = current.authorId;

      if (outcome == ModerationOutcome.hidden ||
          outcome == ModerationOutcome.warned) {
        _hidden.add(current.targetId);
      }
      if (outcome == ModerationOutcome.warned) {
        final warning = await warnings.create(
          userId: authorId!,
          reason: current.reason.label,
          preview: current.preview,
        );
        await notifications?.add(
          recipientId: authorId,
          type: NotificationType.moderatorWarning,
          title: 'A moderator sent you a warning',
          body: 'Reason: ${current.reason.label}',
          targetRoute: '/warning/${warning.id}',
        );
      }
      return _cases[i] = current.copyWith(
        outcome: outcome,
        level: outcome == ModerationOutcome.escalated ? 2 : null,
      );
    } finally {
      _inFlight.remove(caseId);
    }
  }

  @override
  Future<List<ModerationCase>> getAdminQueue() async {
    await Future.delayed(latency);
    return List.unmodifiable(
      _cases.where((x) => x.outcome == ModerationOutcome.escalated),
    );
  }

  @override
  bool isHidden(String targetId) => _hidden.contains(targetId);

  @override
  Future<ModerationCase> fileReport(Report report) {
    final key = '${report.targetId}|${report.reporterId}';
    // The cleanup must not return the removed future: whenComplete would
    // wait on it, i.e. on itself.
    return _filing[key] ??= _file(report).whenComplete(() {
      _filing.remove(key);
    });
  }

  Future<ModerationCase> _file(Report report) async {
    await Future.delayed(latency);
    final content = ModeratedContent.fromReportTarget(report.targetType);
    final communityId = report.communityId;
    if (content == null || communityId == null || communityId.isEmpty) {
      throw ArgumentError.value(
        report.targetType,
        'report',
        'only community content with a community id is moderated here',
      );
    }
    // Counting is per reporter, so a report must say who sent it.
    final reporter = report.reporterId ?? '';
    if (reporter.isEmpty) {
      throw ArgumentError.value(reporter, 'reporterId', 'required');
    }
    if (reporter == report.targetUserId) {
      throw ArgumentError.value(reporter, 'reporterId', 'own content');
    }

    final i = _cases.indexWhere(
      (x) => x.targetId == report.targetId && x.isOpen,
    );
    if (i == -1) {
      final created = ModerationCase(
        id: 'case-filed-${++_filedCount}',
        communityId: communityId,
        content: content,
        targetId: report.targetId,
        authorId: report.targetUserId,
        authorName: report.targetUserName ?? 'Anonymous',
        preview: report.preview ?? '',
        reason: report.reason,
        reportCount: 1,
        firstReporterName: report.reporterName ?? 'A member',
        reportedAt: DateTime.now(),
      );
      _cases.add(created);
      _reporters[created.id] = {reporter};
      _reasonCounts[created.id] = {report.reason: 1};
      return created;
    }

    final current = _cases[i];
    final reporters = _reporters.putIfAbsent(current.id, () => {});
    if (!reporters.add(reporter)) return current;
    final counts = _reasonCounts.putIfAbsent(
      current.id,
      () => {current.reason: current.reportCount},
    );
    counts[report.reason] = (counts[report.reason] ?? 0) + 1;
    var top = current.reason;
    for (final MapEntry(:key, :value) in counts.entries) {
      if (value > (counts[top] ?? 0)) top = key;
    }
    return _cases[i] = current.copyWith(
      reportCount: current.reportCount + 1,
      reason: top,
    );
  }
}
