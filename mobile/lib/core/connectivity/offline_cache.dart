import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';
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

  /// Forgets everything (sign-out).
  void clear() => _items.clear();
}

final offlineCacheProvider = Provider<OfflineCache>((ref) => OfflineCache());

/// Loads with [load] and remembers the result under [key]; while offline it
/// returns the remembered copy instead (falling back to [load] when there
/// is none, which a real backend would fail).
///
/// With the real API this is a plain [load]: the API client already serves
/// the copy saved on the phone (SQLite) while offline, and that copy
/// includes writes made offline, which this in-memory snapshot would hide.
Future<T> loadWithOfflineCache<T>(
  Ref ref,
  String key,
  Future<T> Function() load,
) async {
  if (ref.read(liveApiEnabledProvider)) return load();
  final cache = ref.read(offlineCacheProvider);
  if (!ref.read(connectivityServiceProvider).isOnline) {
    final saved = cache.read<T>(key);
    if (saved != null) return saved;
  }
  final data = await load();
  cache.save(key, data);
  return data;
}
