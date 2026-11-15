import '../../../core/network/api_client.dart';
import '../../community/domain/user_role.dart';
import '../../messaging/domain/report.dart';
import '../domain/moderation_case.dart';
import 'moderation_queue_repository.dart';

/// [ModerationQueueRepository] backed by the FCU API: what a super-mentor
/// sees on "Reports to review" for their own community. Warning an author
/// also hides the content, records the warning and notifies them (all on the
/// server). "Escalate" hands the case to the FCU team's back office queue.
class RemoteModerationQueueRepository implements ModerationQueueRepository {
  RemoteModerationQueueRepository(this._api);

  final ApiClient _api;

  /// Content this device hid through a case; the server keeps it out of every
  /// list afterwards.
  final Set<String> _hidden = {};

  static ModeratedContent _content(String? c) {
    switch (c) {
      case 'comment':
        return ModeratedContent.comment;
      case 'prayer_request':
        return ModeratedContent.prayerRequest;
      case 'testimony':
        return ModeratedContent.testimony;
      default:
        return ModeratedContent.post;
    }
  }

  static ReportReason _reason(String? r) {
    switch (r) {
      case 'harassment_bullying':
        return ReportReason.harassment;
      case 'offensive_content':
        return ReportReason.offensiveContent;
      case 'breaks_community_rules':
        return ReportReason.breakingRules;
      case 'spam_or_fake_profile':
        return ReportReason.spamOrFakeProfile;
      default:
        return ReportReason.somethingElse;
    }
  }

  static ModerationOutcome? _outcome(String? o) {
    switch (o) {
      case 'kept':
        return ModerationOutcome.kept;
      case 'hidden':
        return ModerationOutcome.hidden;
      case 'warned':
        return ModerationOutcome.warned;
      case 'escalated':
        return ModerationOutcome.escalated;
      default:
        return null;
    }
  }

  ModerationCase _case(Map<String, dynamic> j) {
    final author = objectOf(j['author']);
    return ModerationCase(
      id: j['id'] as String,
      communityId: (j['community_id'] as String?) ?? '',
      content: _content(j['content'] as String?),
      targetId: (j['target_id'] as String?) ?? '',
      authorId: author?['id'] as String?,
      authorName: (author?['full_name'] as String?) ?? 'Anonymous',
      preview: (j['preview'] as String?) ?? '',
      reason: _reason(j['reason'] as String?),
      reportCount: (j['report_count'] as int?) ?? 1,
      firstReporterName: (j['first_reporter_name'] as String?) ?? 'A member',
      reportedAt:
          DateTime.tryParse((j['reported_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
      level: (j['level'] as int?) ?? 1,
      outcome: _outcome(j['outcome'] as String?),
    );
  }

  void _requireSuperMentor(UserRole? role, String communityId) {
    if (role != UserRole.superMentor) throw NotSuperMentor(communityId);
  }

  @override
  Future<List<ModerationCase>> getOpenCases(
    String communityId, {
    required UserRole? actorRole,
  }) async {
    _requireSuperMentor(actorRole, communityId);
    try {
      final json = await _api.get('/communities/$communityId/moderation/cases');
      final cases = itemsOf(json).map(_case).toList();
      for (final c in cases) {
        _communityOf[c.id] = communityId;
      }
      return cases;
    } on ApiException catch (e) {
      if (e.status == 403) throw NotSuperMentor(communityId);
      rethrow;
    }
  }

  Future<ModerationCase> _act(
    String caseId,
    UserRole? actorRole,
    String action,
  ) async {
    // Case ids look like "post:<id>"; the community comes from the case.
    final communityId = _communityOf[caseId];
    if (communityId == null) throw ModerationCaseClosed(caseId);
    _requireSuperMentor(actorRole, communityId);
    try {
      final json = objectOf(
        await _api.post(
          '/communities/$communityId/moderation/cases/${Uri.encodeComponent(caseId)}/action',
          body: {'action': action},
        ),
      );
      if (json == null) throw ModerationCaseClosed(caseId);
      final result = _case(json);
      if (action == 'hide' || action == 'warn') _hidden.add(result.targetId);
      return result;
    } on ApiException catch (e) {
      if (e.code == 'case_closed') throw ModerationCaseClosed(caseId);
      if (e.code == 'no_target') throw ModerationAuthorUnknown(caseId);
      if (e.status == 403) throw NotSuperMentor(communityId);
      rethrow;
    }
  }

  final Map<String, String> _communityOf = {};

  @override
  Future<ModerationCase> hide(String caseId, {required UserRole? actorRole}) =>
      _act(caseId, actorRole, 'hide');

  @override
  Future<ModerationCase> warnAuthor(
    String caseId, {
    required UserRole? actorRole,
  }) => _act(caseId, actorRole, 'warn');

  @override
  Future<ModerationCase> keep(String caseId, {required UserRole? actorRole}) =>
      _act(caseId, actorRole, 'keep');

  @override
  Future<ModerationCase> escalate(
    String caseId, {
    required UserRole? actorRole,
  }) => _act(caseId, actorRole, 'escalate');

  /// The FCU team works its queue in the back office, not in the app.
  @override
  Future<List<ModerationCase>> getAdminQueue() async => const [];

  /// Reports are filed through `ReportRepository`, which sends them to the
  /// server; cases are built there from the reports.
  @override
  Future<ModerationCase> fileReport(Report report) =>
      throw UnsupportedError('File reports through ReportRepository');

  @override
  bool isHidden(String targetId) => _hidden.contains(targetId);
}
