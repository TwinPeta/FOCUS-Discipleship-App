enum LearningKind { video, devotional, quiz, document }

/// The common header of every learning item, keyed by the resource or
/// pathway-step id it belongs to.
class LearningItem {
  const LearningItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    this.topicLabel,
  });

  final String id;
  final LearningKind kind;
  final String title;
  final String description;
  final String? topicLabel;
}

class VideoContent {
  const VideoContent({required this.item, required this.duration});
  final LearningItem item;
  final Duration duration;
}

class DevotionalContent {
  const DevotionalContent({
    required this.item,
    required this.reference,
    required this.readMinutes,
    required this.paragraphs,
    required this.thinkAbout,
  });

  final LearningItem item;
  final String reference;
  final int readMinutes;
  final List<String> paragraphs;
  final String thinkAbout;
}

class DocumentContent {
  const DocumentContent({
    required this.item,
    required this.format,
    required this.sizeLabel,
    required this.pageCount,
  });

  final LearningItem item;
  final String format;
  final String sizeLabel;
  final int pageCount;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  }) : assert(options.length == 4);

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class Quiz {
  const Quiz({
    required this.item,
    required this.questions,
    this.passMark = defaultPassMark,
  });

  /// 70% (assumption; configurable per quiz).
  static const defaultPassMark = 0.7;

  final LearningItem item;
  final List<QuizQuestion> questions;
  final double passMark;

  /// Scores [answers] (one option index per question, -1 = unanswered).
  QuizAttempt score(List<int> answers) {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (i < answers.length && answers[i] == questions[i].correctIndex) {
        correct++;
      }
    }
    return QuizAttempt(
      quizId: item.id,
      answers: List.unmodifiable(answers),
      correct: correct,
      total: questions.length,
      passed: questions.isNotEmpty && correct / questions.length >= passMark,
    );
  }
}

class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.answers,
    required this.correct,
    required this.total,
    required this.passed,
  });

  final String quizId;
  final List<int> answers;
  final int correct;
  final int total;
  final bool passed;
}

/// A private note on a devotional. Only its author ever reads it.
class Reflection {
  const Reflection({
    required this.contentId,
    required this.text,
    required this.updatedAt,
  });

  final String contentId;
  final String text;
  final DateTime updatedAt;
}
