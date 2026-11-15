import '../../community/domain/user_role.dart';
import '../domain/activity_event.dart';
import '../domain/badge.dart';

abstract class ActivityRepository {
  /// Private to the signed-in user — never exposed to other users, logs or
  /// any screen besides My activity.
  Future<List<ActivityEvent>> getEvents();
  Future<List<AppBadge>> getBadges();

  /// Records [event] and returns any badges newly earned as a result. When
  /// [event] has a `sourceId` and an event of the same type and source was
  /// already recorded, nothing is recorded and no badge is returned.
  Future<List<AppBadge>> record(ActivityEvent event);

  /// When each member of [communityId] last did anything, for the
  /// super-mentor's "Members to follow up" (screen 30). Only the timestamp
  /// leaves the repository, never the events. Members with no activity are
  /// absent. Throws [NotSuperMentor] for any other role.
  Future<Map<String, DateTime>> lastActiveByMember(
    String communityId, {
    required UserRole? actorRole,
  });
}

/// Deterministic badge rules over the full event history.
class BadgeRules {
  BadgeRules._();

  static const prayerPartnerThreshold = 5;

  static bool earns(String badgeId, List<ActivityEvent> events) {
    int count(ActivityType t) => events.where((e) => e.type == t).length;
    return switch (badgeId) {
      'first-steps' => events.isNotEmpty,
      'quiz-finisher' => count(ActivityType.quizCompleted) >= 1,
      'prayer-partner' => count(ActivityType.prayed) >= prayerPartnerThreshold,
      'pathway-complete' => count(ActivityType.pathwayCompleted) >= 1,
      _ => false,
    };
  }
}
