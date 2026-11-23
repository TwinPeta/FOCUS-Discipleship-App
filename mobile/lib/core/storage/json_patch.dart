/// Small edits to saved API replies, so an offline write shows up in the
/// saved copy of every list and detail that contains it.
library;

/// Returns [json] with every map whose `id` is [id] replaced by [update]
/// of it; [json] itself (identical) when nothing matched.
Object? patchEntity(
  Object? json,
  String id,
  Map<String, dynamic> Function(Map<String, dynamic> entity) update,
) {
  if (json is Map<String, dynamic>) {
    if (json['id'] == id) return update(Map<String, dynamic>.of(json));
    Map<String, dynamic>? copy;
    for (final entry in json.entries) {
      final patched = patchEntity(entry.value, id, update);
      if (!identical(patched, entry.value)) {
        (copy ??= Map<String, dynamic>.of(json))[entry.key] = patched;
      }
    }
    return copy ?? json;
  }
  if (json is List) {
    List<Object?>? copy;
    for (var i = 0; i < json.length; i++) {
      final patched = patchEntity(json[i], id, update);
      if (!identical(patched, json[i])) {
        (copy ??= List<Object?>.of(json))[i] = patched;
      }
    }
    return copy ?? json;
  }
  return json;
}

/// Adds [item] to the `items` of a list reply (first or last). Returns
/// [json] unchanged when it is not a list reply or already has the item.
Object? insertItem(Object? json, Map<String, dynamic> item, {bool atEnd = false}) {
  if (json is! Map<String, dynamic>) return json;
  final items = json['items'];
  if (items is! List) return json;
  if (items.any((e) => e is Map && e['id'] == item['id'])) return json;
  return {
    ...json,
    'items': atEnd ? [...items, item] : [item, ...items],
  };
}

/// Removes the entity with [id] from every list in [json].
Object? removeEntity(Object? json, String id) {
  if (json is Map<String, dynamic>) {
    Map<String, dynamic>? copy;
    for (final entry in json.entries) {
      final patched = removeEntity(entry.value, id);
      if (!identical(patched, entry.value)) {
        (copy ??= Map<String, dynamic>.of(json))[entry.key] = patched;
      }
    }
    return copy ?? json;
  }
  if (json is List) {
    final kept = [
      for (final e in json)
        if (!(e is Map && e['id'] == id)) removeEntity(e, id),
    ];
    final same =
        kept.length == json.length &&
        Iterable<int>.generate(kept.length).every((i) => identical(kept[i], json[i]));
    return same ? json : kept;
  }
  return json;
}
