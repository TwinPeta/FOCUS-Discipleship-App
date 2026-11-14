import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';

/// In-memory copy of the last successfully loaded lists (feeds, prayer
/// walls), served instead of a network call while offline (screen 56).
class OfflineCache {
  final Map<String, Object?> _items = {};

  void save(String key, Object? data) => _items[key] = data;

  T? read<T>(String key) {
    final value = _items[key];
    return value is T ? value : null;
  }
}

final offlineCacheProvider = Provider<OfflineCache>((ref) => OfflineCache());

/// Loads with [load] and remembers the result under [key]; while offline it
/// returns the remembered copy instead (falling back to [load] when there
/// is none, which a real backend would fail).
Future<T> loadWithOfflineCache<T>(
  Ref ref,
  String key,
  Future<T> Function() load,
) async {
  final cache = ref.read(offlineCacheProvider);
  if (!ref.read(connectivityServiceProvider).isOnline) {
    final saved = cache.read<T>(key);
    if (saved != null) return saved;
  }
  final data = await load();
  cache.save(key, data);
  return data;
}
