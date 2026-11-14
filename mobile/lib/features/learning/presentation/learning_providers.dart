import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../activity/domain/activity_event.dart';
import '../../activity/domain/badge.dart';
import '../../activity/presentation/providers/activity_providers.dart';
import '../../pathways/domain/pathway_step.dart';
import '../../pathways/presentation/providers/pathway_providers.dart';
import '../domain/learning_models.dart';

final videoContentProvider = FutureProvider.autoDispose
    .family<VideoContent, String>(
      (ref, id) => ref.watch(learningRepositoryProvider).getVideo(id),
    );

final devotionalContentProvider = FutureProvider.autoDispose
    .family<DevotionalContent, String>(
      (ref, id) => ref.watch(learningRepositoryProvider).getDevotional(id),
    );

final quizProvider = FutureProvider.autoDispose.family<Quiz, String>(
  (ref, id) => ref.watch(learningRepositoryProvider).getQuiz(id),
);

final documentContentProvider = FutureProvider.autoDispose
    .family<DocumentContent, String>(
      (ref, id) => ref.watch(learningRepositoryProvider).getDocument(id),
    );

final lastQuizAttemptProvider = FutureProvider.autoDispose
    .family<QuizAttempt?, String>(
      (ref, id) => ref.watch(learningRepositoryProvider).lastAttempt(id),
    );

final isCompleteProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(learningRepositoryProvider).isComplete(id),
);

/// Where a viewer was opened from: a pathway step (with its community) or
/// the Resources tab.
typedef LearningOrigin = ({String? pathwayId, String? communityId});

/// The viewer route for [kind]/[id]. Pathway steps add `pathway` (the step
/// id is the content id) so viewers can show "Next in pathway".
String learningRoute(
  LearningKind kind,
  String id, {
  String? pathwayId,
  String? communityId,
}) {
  final base = switch (kind) {
    LearningKind.video => '/resources/video/$id',
    LearningKind.devotional => '/devotional/$id',
    LearningKind.quiz => '/quiz/$id',
    LearningKind.document => '/document/$id',
  };
  final query = {'pathway': ?pathwayId, 'community': ?communityId};
  return query.isEmpty
      ? base
      : Uri(path: base, queryParameters: query).toString();
}

LearningKind kindForStep(PathwayStepType type) => switch (type) {
  PathwayStepType.video => LearningKind.video,
  PathwayStepType.devotional => LearningKind.devotional,
  PathwayStepType.quiz => LearningKind.quiz,
};

/// The step after [stepId] in [pathwayId], or null (last step / not a
/// pathway).
final nextPathwayStepProvider = Provider.autoDispose
    .family<PathwayStep?, ({String pathwayId, String stepId})>((ref, key) {
      final steps =
          ref.watch(pathwayStepsProvider(key.pathwayId)).valueOrNull ??
          const <PathwayStep>[];
      final index = steps.indexWhere((s) => s.id == key.stepId);
      if (index == -1 || index + 1 >= steps.length) return null;
      return steps[index + 1];
    });

/// Badges waiting to be celebrated on the Badge earned screen (38).
class BadgeQueue extends Notifier<List<AppBadge>> {
  @override
  List<AppBadge> build() => const [];

  void addAll(Iterable<AppBadge> badges) {
    final ids = {for (final b in state) b.id};
    state = [...state, ...badges.where((b) => ids.add(b.id))];
  }

  AppBadge? get next => state.isEmpty ? null : state.first;

  void dismiss(String badgeId) =>
      state = state.where((b) => b.id != badgeId).toList();

  void clear() => state = const [];
}

final badgeQueueProvider = NotifierProvider<BadgeQueue, List<AppBadge>>(
  BadgeQueue.new,
);

/// Completing any learning item: records the activity, advances the
/// pathway step when opened from one (strictly sequential, enforced by the
/// repository) and queues any badges earned.
class LearningActions {
  LearningActions(this._ref);
  final Ref _ref;

  static ActivityType _activityFor(LearningKind kind) => switch (kind) {
    LearningKind.video => ActivityType.videoWatched,
    LearningKind.devotional => ActivityType.devotionalRead,
    LearningKind.quiz => ActivityType.quizCompleted,
    LearningKind.document => ActivityType.documentRead,
  };

  static String _labelFor(LearningItem item) => switch (item.kind) {
    LearningKind.video => 'Watched "${item.title}"',
    LearningKind.devotional => 'Read "${item.title}"',
    LearningKind.quiz => 'Completed "${item.title}"',
    LearningKind.document => 'Read "${item.title}"',
  };

  /// Returns the badges newly earned (also queued for screen 38).
  Future<List<AppBadge>> complete(
    LearningItem item, {
    String? pathwayId,
    bool alreadyStored = false,
  }) async {
    if (!alreadyStored) {
      await _ref.read(learningRepositoryProvider).markComplete(item.id);
    }
    final earned = <AppBadge>[
      ...await _ref
          .read(activityRecorderProvider)
          .record(_activityFor(item.kind), _labelFor(item), sourceId: item.id),
    ];
    if (pathwayId != null) {
      final steps = await _ref.read(pathwayStepsProvider(pathwayId).future);
      final step = steps.where((s) => s.id == item.id).firstOrNull;
      if (step != null && step.status == PathwayStepStatus.current) {
        earned.addAll(
          await _ref
              .read(pathwayStepsProvider(pathwayId).notifier)
              .completeStep(step.id),
        );
      }
    }
    _ref.invalidate(isCompleteProvider(item.id));
    _ref.read(badgeQueueProvider.notifier).addAll(earned);
    return earned;
  }

  /// Scores the quiz in the repository; a pass completes it like any item.
  Future<({QuizAttempt attempt, List<AppBadge> badges})> submitQuiz(
    Quiz quiz,
    List<int> answers, {
    String? pathwayId,
  }) async {
    final attempt = await _ref
        .read(learningRepositoryProvider)
        .submitQuiz(quiz.item.id, answers);
    _ref.invalidate(lastQuizAttemptProvider(quiz.item.id));
    if (!attempt.passed) return (attempt: attempt, badges: const <AppBadge>[]);
    final badges = await complete(
      quiz.item,
      pathwayId: pathwayId,
      alreadyStored: true,
    );
    return (attempt: attempt, badges: badges);
  }
}

final learningActionsProvider = Provider<LearningActions>(LearningActions.new);
