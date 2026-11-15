import 'package:focus_1/features/moderation/data/warning_repository.dart';
import 'package:focus_1/features/moderation/domain/warning.dart';

class FakeWarningRepository implements WarningRepository {
  FakeWarningRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  final List<Warning> _items = [];
  var _counter = 0;

  @override
  Future<Warning> create({
    required String userId,
    required String reason,
    required String preview,
  }) async {
    // Synchronous record, like notifications, so the caller can link to it.
    final warning = Warning(
      id: 'warning-${++_counter}',
      userId: userId,
      reason: reason,
      preview: preview,
      createdAt: DateTime.now(),
    );
    _items.add(warning);
    return warning;
  }

  @override
  Future<List<Warning>> getWarningsFor(String userId) async {
    await Future.delayed(latency);
    final mine = _items.where((w) => w.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(mine);
  }

  @override
  Future<Warning> acknowledge(String id) async {
    await Future.delayed(latency);
    final i = _items.indexWhere((w) => w.id == id);
    if (i == -1) throw ArgumentError.value(id, 'id', 'unknown warning');
    return _items[i] = _items[i].copyWith(acknowledged: true);
  }
}
