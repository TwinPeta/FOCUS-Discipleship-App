import '../../community/domain/user_role.dart';
import '../../messaging/domain/report.dart';
import '../domain/moderation_case.dart';

/// Level 1 moderation for one community (screen 32). Every action takes the
/// actor's role and throws [NotSuperMentor] unless it is a super-mentor.
/// Each action records an outcome and removes the case from the queue.
abstract class ModerationQueueRepository {
  /// Open cases for [communityId], oldest first.
  Future<List<ModerationCase>> getOpenCases(
    String communityId, {
    required UserRole? actorRole,
  });

  /// Hides the content for everyone.
  Future<ModerationCase> hide(String caseId, {required UserRole? actorRole});

  /// Hides the content, creates a [Warning] for the author and notifies
  /// them.
  Future<ModerationCase> warnAuthor(
    String caseId, {
    required UserRole? actorRole,
  });

  /// Leaves the content up.
  Future<ModerationCase> keep(String caseId, {required UserRole? actorRole});

  /// Moves the case to the admin team's queue.
  Future<ModerationCase> escalate(
    String caseId, {
    required UserRole? actorRole,
  });

  /// Cases waiting for the admin team (a backend owns this queue).
  Future<List<ModerationCase>> getAdminQueue();

  /// Files a member's report of community content (from `ReportFlow`).
  /// Opens a level 1 case for the content, or adds to its open case: the
  /// count goes up once per reporter and the case's reason becomes the most
  /// common one. A second report from the same person changes nothing, and
  /// a repeated call while one is in flight returns the same result.
  /// Throws [ArgumentError] for targets that are not community content, for
  /// a report without a community or a reporter id, or for reporting your
  /// own content.
  Future<ModerationCase> fileReport(Report report);

  /// True when moderation hid this post/comment/prayer for everyone. Feeds
  /// filter on it in the data layer.
  bool isHidden(String targetId);
}
