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

class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  final List<ActivityEvent> _events = [];
  final List<AppBadge> _badges = const [
    AppBadge(id: 'first-steps', name: 'First steps'),
    AppBadge(id: 'quiz-finisher', name: 'Quiz finisher'),
    AppBadge(id: 'prayer-partner', name: 'Prayer partner'),
    AppBadge(id: 'pathway-complete', name: 'Pathway complete'),
  ].toList();

  @override
  Future<List<ActivityEvent>> getEvents() async {
    await Future.delayed(latency);
    return List.unmodifiable(_events.reversed);
  }

  @override
  Future<List<AppBadge>> getBadges() async {
    await Future.delayed(latency);
    return List.unmodifiable(_badges);
  }

  @override
  Future<List<AppBadge>> record(ActivityEvent event) async {
    await Future.delayed(latency);
    final duplicate =
        event.sourceId != null &&
        _events.any(
          (e) => e.type == event.type && e.sourceId == event.sourceId,
        );
    if (duplicate) return const [];
    _events.add(event);

    final newlyEarned = <AppBadge>[];
    for (var i = 0; i < _badges.length; i++) {
      final badge = _badges[i];
      if (!badge.earned && BadgeRules.earns(badge.id, _events)) {
        _badges[i] = badge.copyWith(earned: true);
        newlyEarned.add(_badges[i]);
      }
    }
    return newlyEarned;
  }
}
