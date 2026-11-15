import '../domain/warning.dart';

abstract class WarningRepository {
  Future<Warning> create({
    required String userId,
    required String reason,
    required String preview,
  });

  /// Newest first.
  Future<List<Warning>> getWarningsFor(String userId);

  Future<Warning> acknowledge(String id);
}
