import '../../../core/network/api_client.dart';
import '../../../core/storage/json_patch.dart';
import '../../../core/sync/outbox.dart';
import '../domain/learning_models.dart';
import 'learning_repository.dart';

/// [LearningRepository] backed by the FCU API: content comes from
/// `/resources`, progress from `/resources/{id}/progress`, private
/// reflections from `/resources/{id}/reflection`, and quizzes are scored by
/// the server (correct answers never reach the app). The last attempt
/// (score and the member's own choices) comes back with the quiz.
class RemoteLearningRepository implements LearningRepository {
  RemoteLearningRepository(this._api, {Outbox? outbox})
    : _outbox = outbox ?? Outbox(api: _api);

  final ApiClient _api;
  final Outbox _outbox;

  static String _stamp() => '${DateTime.now().microsecondsSinceEpoch}';

  /// Merges [fields] into `my_progress` of the saved copies of [id].
  static Object? Function(String, Object?) _progress(
    String id,
    Map<String, Object> fields,
  ) => (_, json) => patchEntity(json, id, (m) {
    m['my_progress'] = {...?objectOf(m['my_progress']), ...fields};
    return m;
  });

  final Map<String, List<List<String>>> _optionIds =
      {}; // quiz -> question -> option ids
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
      streamUrl: j['stream_url'] as String?,
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
    final url = (j['document_url'] as String?)?.trim();
    // The type from the file name (a signed link carries a query string).
    final path = Uri.tryParse(url ?? '')?.path ?? '';
    final name = path.substring(path.lastIndexOf('/') + 1);
    final dot = name.lastIndexOf('.');
    return DocumentContent(
      item: _item(j, LearningKind.document),
      format: dot <= 0 ? 'Document' : name.substring(dot + 1).toUpperCase(),
      sizeLabel: _size(j['file_size_bytes'] as int?),
      url: (url == null || url.isEmpty) ? null : url,
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
    _lastAttempts[id] = _attemptFrom(id, objectOf(j['my_last_attempt']));
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

  /// The last attempt read with each quiz (null when there is none).
  final Map<String, QuizAttempt?> _lastAttempts = {};

  /// Turns the server's `my_last_attempt` into option indexes per question
  /// (-1 where a question was left out).
  QuizAttempt? _attemptFrom(String quizId, Map<String, dynamic>? j) {
    if (j == null) return null;
    final chosen = <String, String>{
      for (final a in (j['answers'] as List?) ?? const [])
        if (a is Map<String, dynamic>)
          (a['question_id'] as String?) ?? '':
              (a['option_id'] as String?) ?? '',
    };
    final questions = _questionIds[quizId] ?? const <String>[];
    final options = _optionIds[quizId] ?? const <List<String>>[];
    return QuizAttempt(
      quizId: quizId,
      answers: List.unmodifiable([
        for (var i = 0; i < questions.length; i++)
          options[i].indexOf(chosen[questions[i]] ?? ''),
      ]),
      correct: (j['score'] as int?) ?? 0,
      total: (j['total'] as int?) ?? questions.length,
      passed: j['passed'] == true,
    );
  }

  Reflection? _reflectionFrom(String contentId, Map<String, dynamic>? j) {
    final text = (j?['text'] as String?) ?? '';
    if (text.isEmpty) return null;
    return Reflection(
      contentId: contentId,
      text: text,
      updatedAt:
          DateTime.tryParse((j?['updated_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  @override
  Future<Reflection?> getReflection(String contentId) async => _reflectionFrom(
    contentId,
    objectOf(await _api.get('/resources/$contentId/reflection')),
  );

  @override
  Future<Reflection> saveReflection(String contentId, String text) async {
    final saved = <String, dynamic>{'text': text, 'updated_at': apiNow()};
    final path = '/resources/$contentId/reflection';
    final json = objectOf(
      (await _outbox.write(
        OfflineWrite(
          method: 'PUT',
          endpoint: path,
          entityType: 'reflection',
          clientId: 'reflection-$contentId-${_stamp()}',
          coalesceKey: 'reflection:$contentId',
          body: {'text': text},
          optimistic: saved,
          patchWhere: (key) => cachedPathOf(key) == path,
          patch: (_, _) => saved,
        ),
      )).json,
    );
    return _reflectionFrom(contentId, json) ??
        Reflection(contentId: contentId, text: text, updatedAt: DateTime.now());
  }

  @override
  Future<Duration> getResumePosition(String videoId) async {
    final j = await _resource(videoId);
    final progress = objectOf(j['my_progress']);
    return Duration(seconds: (progress?['position_seconds'] as int?) ?? 0);
  }

  @override
  Future<void> saveResumePosition(String videoId, Duration position) async {
    await _outbox.write(
      OfflineWrite(
        method: 'PUT',
        endpoint: '/resources/$videoId/progress',
        entityType: 'video_progress',
        clientId: 'position-$videoId-${_stamp()}',
        coalesceKey: 'video_progress:$videoId',
        body: {'position_seconds': position.inSeconds},
        patch: _progress(videoId, {'position_seconds': position.inSeconds}),
      ),
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
        body.add({
          'question_id': questions[i],
          'option_id': options[i][choice],
        });
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
    return _lastAttempts[quizId] = attempt;
  }

  @override
  Future<QuizAttempt?> lastAttempt(String quizId) async {
    // Read with the quiz; fetch it when this quiz was not opened yet.
    if (!_lastAttempts.containsKey(quizId)) await getQuiz(quizId);
    return _lastAttempts[quizId];
  }

  @override
  Future<void> markComplete(String contentId) async {
    await _outbox.write(
      OfflineWrite(
        method: 'PUT',
        endpoint: '/resources/$contentId/progress',
        entityType: 'progress',
        clientId: 'complete-$contentId-${_stamp()}',
        coalesceKey: 'progress:$contentId',
        body: {'completed': true},
        patch: _progress(contentId, {'completed': true}),
      ),
    );
  }

  @override
  Future<bool> isComplete(String contentId) async {
    final j = await _resource(contentId);
    return objectOf(j['my_progress'])?['completed'] == true;
  }
}
