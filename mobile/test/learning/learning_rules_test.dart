import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/features/activity/data/activity_repository.dart';
import 'package:focus_1/features/activity/domain/activity_event.dart';
import 'package:focus_1/features/activity/domain/badge.dart';
import 'package:focus_1/features/learning/data/learning_repository.dart';
import 'package:focus_1/features/learning/domain/learning_models.dart';
import 'package:focus_1/features/learning/domain/playback_controller.dart';
import 'package:focus_1/features/learning/presentation/learning_providers.dart';
import 'package:focus_1/features/pathways/data/pathway_repository.dart';
import 'package:focus_1/features/pathways/domain/pathway_step.dart';
import 'package:focus_1/features/pathways/presentation/providers/pathway_providers.dart';

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      learningRepositoryProvider.overrideWithValue(
        FakeLearningRepository(latency: Duration.zero),
      ),
      pathwayRepositoryProvider.overrideWithValue(
        FakePathwayRepository(latency: Duration.zero),
      ),
      activityRepositoryProvider.overrideWithValue(
        FakeActivityRepository(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

List<int> _answers(Quiz quiz, int correct) => [
  for (var i = 0; i < quiz.questions.length; i++)
    i < correct
        ? quiz.questions[i].correctIndex
        : (quiz.questions[i].correctIndex + 1) % 4,
];

void main() {
  group('quiz scoring', () {
    late Quiz quiz;
    setUp(() async {
      quiz = await FakeLearningRepository(latency: Duration.zero)
          .getQuiz('resource-3');
    });

    test('70% passes, 60% does not', () {
      expect(quiz.questions, hasLength(10));
      expect(quiz.score(_answers(quiz, 7)).passed, isTrue);
      final fail = quiz.score(_answers(quiz, 6));
      expect(fail.correct, 6);
      expect(fail.passed, isFalse);
    });

    test('unanswered questions count as wrong', () {
      final attempt = quiz.score(const [-1]);
      expect(attempt.correct, 0);
      expect(attempt.total, 10);
    });

    test('pass mark is configurable', () {
      final strict = Quiz(
        item: quiz.item,
        questions: quiz.questions,
        passMark: 0.9,
      );
      expect(strict.score(_answers(quiz, 8)).passed, isFalse);
    });
  });

  test('a failed quiz is not complete and earns nothing', () async {
    final c = _container();
    final quiz = await c.read(learningRepositoryProvider).getQuiz('resource-3');
    final result = await c
        .read(learningActionsProvider)
        .submitQuiz(quiz, _answers(quiz, 3));
    expect(result.attempt.passed, isFalse);
    expect(result.badges, isEmpty);
    expect(
      await c.read(learningRepositoryProvider).isComplete('resource-3'),
      isFalse,
    );
    expect(await c.read(activityRepositoryProvider).getEvents(), isEmpty);
  });

  test('passing a pathway quiz records activity, advances the step and '
      'queues badges', () async {
    final c = _container();
    const pathwayId = 'pathway-1';
    // Step 3 (the quiz) is current in the seed.
    final quiz = await c
        .read(learningRepositoryProvider)
        .getQuiz('pathway-1-step-3');
    final result = await c
        .read(learningActionsProvider)
        .submitQuiz(quiz, _answers(quiz, 10), pathwayId: pathwayId);

    expect(result.attempt.passed, isTrue);
    final events = await c.read(activityRepositoryProvider).getEvents();
    expect(events.map((e) => e.type), contains(ActivityType.quizCompleted));

    final steps = await c.read(pathwayStepsProvider(pathwayId).future);
    expect(steps[2].status, PathwayStepStatus.done);
    expect(steps[3].status, PathwayStepStatus.current);

    final ids = result.badges.map((b) => b.id).toSet();
    expect(ids, containsAll(['first-steps', 'quiz-finisher']));
    expect(c.read(badgeQueueProvider).map((b) => b.id).toSet(), ids);
  });

  test('completing the last step completes the pathway', () async {
    final c = _container();
    final actions = c.read(learningActionsProvider);
    final repo = c.read(learningRepositoryProvider);
    final quiz = await repo.getQuiz('pathway-1-step-3');
    await actions.submitQuiz(quiz, _answers(quiz, 10), pathwayId: 'pathway-1');
    final video = await repo.getVideo('pathway-1-step-4');
    final badges = await actions.complete(video.item, pathwayId: 'pathway-1');

    expect(badges.map((b) => b.id), contains('pathway-complete'));
    final steps = await c.read(pathwayStepsProvider('pathway-1').future);
    expect(steps.every((s) => s.status == PathwayStepStatus.done), isTrue);
  });

  test(
    'a step that is not current is not advanced (strictly sequential)',
    () async {
      final c = _container();
      final video = await c
          .read(learningRepositoryProvider)
          .getVideo('pathway-1-step-4');
      await c
          .read(learningActionsProvider)
          .complete(video.item, pathwayId: 'pathway-1');
      final steps = await c.read(pathwayStepsProvider('pathway-1').future);
      expect(steps[2].status, PathwayStepStatus.current);
      expect(steps[3].status, PathwayStepStatus.locked);
    },
  );

  test('badge queue de-duplicates and clears', () {
    final c = _container();
    final queue = c.read(badgeQueueProvider.notifier);
    const a = AppBadge(id: 'a', name: 'A', earned: true);
    queue.addAll([a, a]);
    expect(c.read(badgeQueueProvider), hasLength(1));
    queue.clear();
    expect(c.read(badgeQueueProvider), isEmpty);
  });

  test('reflections and resume positions are stored per item', () async {
    final repo = FakeLearningRepository(latency: Duration.zero);
    expect(await repo.getReflection('resource-2'), isNull);
    await repo.saveReflection('resource-2', 'My thoughts');
    expect((await repo.getReflection('resource-2'))!.text, 'My thoughts');

    await repo.saveResumePosition('resource-1', const Duration(seconds: 130));
    expect(
      await repo.getResumePosition('resource-1'),
      const Duration(seconds: 130),
    );
    expect(await repo.getResumePosition('resource-5'), Duration.zero);
  });

  test('unknown or mismatched content ids throw ContentNotFound', () {
    final repo = FakeLearningRepository(latency: Duration.zero);
    expect(repo.getVideo('nope'), throwsA(isA<ContentNotFound>()));
    // resource-2 is a devotional, not a video.
    expect(repo.getVideo('resource-2'), throwsA(isA<ContentNotFound>()));
  });

  testWidgets('fake playback advances while playing and stops at the end', (
    tester,
  ) async {
    final player = FakePlaybackController(
      duration: const Duration(seconds: 5),
      start: const Duration(seconds: 2),
    );
    player.play();
    await tester.pump(const Duration(seconds: 2));
    expect(player.position, const Duration(seconds: 4));
    expect(player.isPlaying, isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(player.position, const Duration(seconds: 5));
    expect(player.isPlaying, isFalse);
    player.dispose();
  });
}
