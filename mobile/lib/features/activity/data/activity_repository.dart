import '../domain/activity_event.dart';
import '../domain/badge.dart';

abstract class ActivityRepository {
  /// Private to the signed-in user — never exposed to other users, logs or
  /// any screen besides My activity.
  Future<List<ActivityEvent>> getEvents();
  Future<List<AppBadge>> getBadges();

  /// Records [event] and returns any badges newly earned as a result.
  Future<List<AppBadge>> record(ActivityEvent event);
}

class FakeActivityRepository implements ActivityRepository {
  static const _latency = Duration(milliseconds: 300);

  final List<ActivityEvent> _events = [];
  final List<AppBadge> _badges = const [
    AppBadge(id: 'first-steps', name: 'First steps'),
    AppBadge(id: 'quiz-finisher', name: 'Quiz finisher'),
    AppBadge(id: 'prayer-partner', name: 'Prayer partner'),
    AppBadge(id: 'pathway-complete', name: 'Pathway complete'),
  ].toList();

  @override
  Future<List<ActivityEvent>> getEvents() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_events.reversed);
  }

  @override
  Future<List<AppBadge>> getBadges() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_badges);
  }

  @override
  Future<List<AppBadge>> record(ActivityEvent event) async {
    await Future.delayed(_latency);
    _events.add(event);

    final newlyEarned = <AppBadge>[];
    void tryAward(String id, bool earns) {
      final index = _badges.indexWhere((b) => b.id == id);
      if (!_badges[index].earned && earns) {
        _badges[index] = _badges[index].copyWith(earned: true);
        newlyEarned.add(_badges[index]);
      }
    }

    tryAward('first-steps', _events.isNotEmpty);
    tryAward('quiz-finisher', event.type == 'quiz_completed');
    tryAward(
      'prayer-partner',
      _events.where((e) => e.type == 'prayed').length >= 5,
    );
    tryAward('pathway-complete', event.type == 'pathway_completed');

    return newlyEarned;
  }
}
