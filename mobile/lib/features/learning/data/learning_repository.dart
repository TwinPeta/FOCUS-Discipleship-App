import '../domain/learning_models.dart';

class ContentNotFound implements Exception {
  const ContentNotFound(this.id);
  final String id;
}

abstract class LearningRepository {
  Future<VideoContent> getVideo(String id);
  Future<DevotionalContent> getDevotional(String id);
  Future<Quiz> getQuiz(String id);
  Future<DocumentContent> getDocument(String id);

  /// Private to the current user.
  Future<Reflection?> getReflection(String contentId);
  Future<Reflection> saveReflection(String contentId, String text);

  Future<Duration> getResumePosition(String videoId);
  Future<void> saveResumePosition(String videoId, Duration position);

  /// Scored here, never trusted from the UI.
  Future<QuizAttempt> submitQuiz(String quizId, List<int> answers);
  Future<QuizAttempt?> lastAttempt(String quizId);

  Future<void> markComplete(String contentId);
  Future<bool> isComplete(String contentId);
}
