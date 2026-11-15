import '../../../core/network/api_client.dart';
import '../domain/learning_models.dart';
import 'learning_repository.dart';

/// [LearningRepository] backed by the FCU API: content comes from
/// `/resources`, progress from `/resources/{id}/progress`, and quizzes are
/// scored by the server (correct answers never reach the app).
///
/// Private reflections have no API yet, so they are kept for this session
/// only.
class RemoteLearningRepository implements LearningRepository {
  RemoteLearningRepository(this._api);

  final ApiClient _api;

  final Map<String, Reflection> _reflections = {};
  final Map<String, QuizAttempt> _attempts = {};
  final Map<String, List<List<String>>> _optionIds = {}; // quiz -> question -> option ids
  final Map<String, List<String>> _questionIds = {};

  Future<Map<String, dynamic>> _resource(String id) async {
    final json = objectOf(await _api.get('/resources/$id'));
    if (json == null) throw ArgumentError.value(id, 'id', 'unknown content');
    return json;
  }

  static String? _topic(String? category) {
    switch (category) {
      case 'bible_characters':
        return 'Bible characters';
      case 'bible_texts':
        return 'Bible texts';
      default:
        return null;
    }
  }

  LearningItem _item(Map<String, dynamic> j, LearningKind kind) => LearningItem(
    id: j['id'] as String,
    kind: kind,
    title: (j['title'] as String?) ?? '',
    description: '',
    topicLabel: _topic(j['category'] as String?),
  );

  @override
  Future<VideoContent> getVideo(String id) async {
    final j = await _resource(id);
    return VideoContent(
      item: _item(j, LearningKind.video),
      duration: Duration(seconds: (j['duration_seconds'] as int?) ?? 0),
    );
  }

  static List<String> _paragraphs(String? html) {
    if (html == null) return const [];
    final text = html
        .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
    return text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  @override
  Future<DevotionalContent> getDevotional(String id) async {
    final j = await _resource(id);
    return DevotionalContent(
      item: _item(j, LearningKind.devotional),
      reference: (j['bible_book'] as String?) ?? '',
      readMinutes: (j['read_minutes'] as int?) ?? 5,
      paragraphs: _paragraphs(j['body_html'] as String?),
      thinkAbout: '',
    );
  }

  static String _size(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Future<DocumentContent> getDocument(String id) async {
    final j = await _resource(id);
    final url = (j['document_url'] as String?) ?? '';
    final dot = url.lastIndexOf('.');
    return DocumentContent(
      item: _item(j, LearningKind.document),
      format: dot == -1 ? 'PDF' : url.substring(dot + 1).toUpperCase(),
      sizeLabel: _size(j['file_size_bytes'] as int?),
      pageCount: 0,
    );
  }

  @override
  Future<Quiz> getQuiz(String id) async {
    final j = objectOf(await _api.get('/quizzes/$id'));
    if (j == null) throw ArgumentError.value(id, 'id', 'unknown quiz');
    final questions = <QuizQuestion>[];
    final optionIds = <List<String>>[];
    final questionIds = <String>[];
    final rawQuestions = j['questions'];
    if (rawQuestions is List) {
      for (final q in rawQuestions.whereType<Map<String, dynamic>>()) {
        final options = (q['options'] is List)
            ? (q['options'] as List).whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];
        optionIds.add([for (final o in options) o['id'] as String]);
        questionIds.add(q['id'] as String);
        questions.add(
          QuizQuestion(
            id: q['id'] as String,
            prompt: (q['text'] as String?) ?? '',
            options: [for (final o in options) (o['text'] as String?) ?? ''],
            // The server never reveals the answer; scoring happens there.
            correctIndex: -1,
          ),
        );
      }
    }
    _optionIds[id] = optionIds;
    _questionIds[id] = questionIds;
    final pass = (j['pass_mark_percent'] as num?)?.toDouble();
    return Quiz(
      item: LearningItem(
        id: id,
        kind: LearningKind.quiz,
        title: (j['title'] as String?) ?? '',
        description: '',
      ),
      questions: questions,
      passMark: pass == null ? Quiz.defaultPassMark : pass / 100,
    );
  }

  @override
  Future<Reflection?> getReflection(String contentId) async =>
      _reflections[contentId];

  @override
  Future<Reflection> saveReflection(String contentId, String text) async =>
      _reflections[contentId] = Reflection(
        contentId: contentId,
        text: text,
        updatedAt: DateTime.now(),
      );

  @override
  Future<Duration> getResumePosition(String videoId) async {
    final j = await _resource(videoId);
    final progress = objectOf(j['my_progress']);
    return Duration(seconds: (progress?['position_seconds'] as int?) ?? 0);
  }

  @override
  Future<void> saveResumePosition(String videoId, Duration position) async {
    await _api.put(
      '/resources/$videoId/progress',
      body: {'position_seconds': position.inSeconds},
    );
  }

  @override
  Future<QuizAttempt> submitQuiz(String quizId, List<int> answers) async {
    if (!_optionIds.containsKey(quizId)) await getQuiz(quizId);
    final options = _optionIds[quizId]!;
    final questions = _questionIds[quizId]!;
    final body = <Map<String, String>>[];
    for (var i = 0; i < questions.length && i < answers.length; i++) {
      final choice = answers[i];
      if (choice >= 0 && choice < options[i].length) {
        body.add({'question_id': questions[i], 'option_id': options[i][choice]});
      }
    }
    final json = objectOf(
      await _api.post('/quizzes/$quizId/attempts', body: {'answers': body}),
    );
    final attempt = QuizAttempt(
      quizId: quizId,
      answers: List.unmodifiable(answers),
      correct: (json?['score'] as int?) ?? 0,
      total: (json?['total'] as int?) ?? questions.length,
      passed: json?['passed'] == true,
    );
    return _attempts[quizId] = attempt;
  }

  @override
  Future<QuizAttempt?> lastAttempt(String quizId) async => _attempts[quizId];

  @override
  Future<void> markComplete(String contentId) async {
    await _api.put(
      '/resources/$contentId/progress',
      body: {'completed': true},
    );
  }

  @override
  Future<bool> isComplete(String contentId) async {
    final j = await _resource(contentId);
    return objectOf(j['my_progress'])?['completed'] == true;
  }
}
