import 'package:focus_1/features/learning/data/learning_repository.dart';
import 'package:focus_1/features/learning/domain/learning_models.dart';
import 'package:focus_1/features/pathways/domain/pathway_step.dart';
import 'package:focus_1/features/resources/domain/resource.dart';

import 'pathway_repository.dart';
import 'resource_repository.dart';

/// Content for every seeded resource and pathway step, generated from
/// their titles (placeholder bodies until real content exists).
class FakeLearningRepository implements LearningRepository {
  FakeLearningRepository({this.latency = const Duration(milliseconds: 300)}) {
    for (final r in FakeResourceRepository.seed) {
      _items[r.id] = LearningItem(
        id: r.id,
        kind: switch (r.type) {
          ResourceType.video => LearningKind.video,
          ResourceType.devotional => LearningKind.devotional,
          ResourceType.quiz => LearningKind.quiz,
          ResourceType.document => LearningKind.document,
        },
        title: r.title,
        description: r.meta,
        topicLabel: switch (r.topic) {
          ResourceTopic.characters => 'Bible characters',
          ResourceTopic.texts => 'Bible texts',
          ResourceTopic.none => null,
        },
      );
    }
    for (final s in FakePathwayRepository.stepCatalog) {
      _items[s.id] = LearningItem(
        id: s.id,
        kind: switch (s.type) {
          PathwayStepType.video => LearningKind.video,
          PathwayStepType.devotional => LearningKind.devotional,
          PathwayStepType.quiz => LearningKind.quiz,
        },
        title: s.title,
        description: s.meta,
        topicLabel: 'Pathway',
      );
    }
  }

  final Duration latency;
  final Map<String, LearningItem> _items = {};
  final Map<String, Reflection> _reflections = {};
  final Map<String, Duration> _positions = {};
  final Map<String, QuizAttempt> _attempts = {};
  final Set<String> _completed = {};

  LearningItem _item(String id, LearningKind kind) {
    final item = _items[id];
    if (item == null || item.kind != kind) throw ContentNotFound(id);
    return item;
  }

  @override
  Future<VideoContent> getVideo(String id) async {
    await Future.delayed(latency);
    return VideoContent(
      item: _item(id, LearningKind.video),
      duration: const Duration(minutes: 8),
    );
  }

  @override
  Future<DevotionalContent> getDevotional(String id) async {
    await Future.delayed(latency);
    final item = _item(id, LearningKind.devotional);
    return DevotionalContent(
      item: item,
      reference: '[Galatians 5:16-25]',
      readMinutes: 5,
      paragraphs: const [
        '[Placeholder] Walking by the Spirit is not a single decision but a '
            'daily direction. Each morning is a new chance to let God shape '
            'how we speak, study and treat the people around us.',
        '[Placeholder] Paul lists love, joy and peace first. They grow '
            'slowly, like fruit, through ordinary habits: prayer, honest '
            'friendship and serving others without being asked.',
      ],
      thinkAbout:
          'Which fruit of the Spirit would you most like to grow this week, '
          'and what one small step could help?',
    );
  }

  @override
  Future<Quiz> getQuiz(String id) async {
    await Future.delayed(latency);
    final item = _item(id, LearningKind.quiz);
    return Quiz(
      item: item,
      questions: [
        for (var i = 0; i < 10; i++)
          QuizQuestion(
            id: '$id-q${i + 1}',
            prompt: _questions[i % _questions.length].$1,
            options: _questions[i % _questions.length].$2,
            correctIndex: _questions[i % _questions.length].$3,
          ),
      ],
    );
  }

  static const _questions = <(String, List<String>, int)>[
    (
      'Who led the Israelites out of Egypt?',
      ['Moses', 'David', 'Elijah', 'Joseph'],
      0,
    ),
    (
      'Which book comes first in the New Testament?',
      ['John', 'Acts', 'Matthew', 'Romans'],
      2,
    ),
    (
      'How many disciples did Jesus choose?',
      ['Seven', 'Ten', 'Twelve', 'Forty'],
      2,
    ),
    (
      'Who was swallowed by a great fish?',
      ['Jonah', 'Peter', 'Noah', 'Daniel'],
      0,
    ),
    (
      'Which fruit of the Spirit is listed first?',
      ['Joy', 'Love', 'Peace', 'Patience'],
      1,
    ),
  ];

  @override
  Future<DocumentContent> getDocument(String id) async {
    await Future.delayed(latency);
    return DocumentContent(
      item: _item(id, LearningKind.document),
      format: 'PDF',
      sizeLabel: '2 MB',
      pageCount: 12,
    );
  }

  @override
  Future<Reflection?> getReflection(String contentId) async {
    await Future.delayed(latency);
    return _reflections[contentId];
  }

  @override
  Future<Reflection> saveReflection(String contentId, String text) async {
    final reflection = Reflection(
      contentId: contentId,
      text: text,
      updatedAt: DateTime.now(),
    );
    _reflections[contentId] = reflection;
    return reflection;
  }

  @override
  Future<Duration> getResumePosition(String videoId) async {
    await Future.delayed(latency);
    return _positions[videoId] ?? Duration.zero;
  }

  @override
  Future<void> saveResumePosition(String videoId, Duration position) async {
    _positions[videoId] = position;
  }

  @override
  Future<QuizAttempt> submitQuiz(String quizId, List<int> answers) async {
    final quiz = await getQuiz(quizId);
    final attempt = quiz.score(answers);
    _attempts[quizId] = attempt;
    if (attempt.passed) _completed.add(quizId);
    return attempt;
  }

  @override
  Future<QuizAttempt?> lastAttempt(String quizId) async {
    await Future.delayed(latency);
    return _attempts[quizId];
  }

  @override
  Future<void> markComplete(String contentId) async {
    await Future.delayed(latency);
    _completed.add(contentId);
  }

  @override
  Future<bool> isComplete(String contentId) async {
    await Future.delayed(latency);
    return _completed.contains(contentId);
  }
}
