import 'package:focus_1/features/activity/data/activity_repository.dart';
import 'package:focus_1/features/activity/domain/activity_event.dart';
import 'package:focus_1/features/activity/domain/badge.dart';
import 'package:focus_1/features/community/domain/user_role.dart';

class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({
    this.latency = const Duration(milliseconds: 300),
    Map<String, DateTime>? memberLastActive,
  }) : _memberLastActive = memberLastActive ?? _seedLastActive();

  final Duration latency;

  /// Other members' last-activity timestamps (a backend derives these from
  /// their events).
  final Map<String, DateTime> _memberLastActive;

  static Map<String, DateTime> _seedLastActive() {
    final now = DateTime.now();
    return {
      'sm-1': now.subtract(const Duration(hours: 2)),
      'm-1': now.subtract(const Duration(days: 1)),
      'member-1': now.subtract(const Duration(days: 2)),
      'member-2': now.subtract(const Duration(days: 21)),
      'member-3': now.subtract(const Duration(days: 5)),
      // member-4 has no activity at all.
    };
  }

  @override
  Future<Map<String, DateTime>> lastActiveByMember(
    String communityId, {
    required UserRole? actorRole,
  }) async {
    await Future.delayed(latency);
    if (actorRole != UserRole.superMentor) throw NotSuperMentor(communityId);
    return Map.unmodifiable(_memberLastActive);
  }

  final List<ActivityEvent> _events = [];
  final List<AppBadge> _badges = const [...kBadgeCatalog].toList();

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
