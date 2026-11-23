import 'dart:convert';

/// A write made while offline, waiting in the outbox (`sync_outbox`) until
/// the server can be reached. Jobs are sent oldest first.
class OutboxJob {
  const OutboxJob({
    this.id,
    required this.accountId,
    required this.clientId,
    required this.entityType,
    required this.method,
    required this.endpoint,
    this.body,
    this.media = const [],
    this.coalesceKey,
    this.status = OutboxStatus.pending,
    this.retryCount = 0,
    this.lastError,
    required this.createdAt,
  });

  /// Row id (insertion order); null before it is stored.
  final int? id;
  final String accountId;

  /// Sent as the `Idempotency-Key`, so a retried job is not stored twice.
  final String clientId;

  /// 'post', 'comment', 'post_like', 'prayer', 'message', 'profile', ...
  final String entityType;
  final String method;
  final String endpoint;
  final Object? body;

  /// Photos and videos to upload before the request; their media ids are
  /// put in the body.
  final List<MediaRef> media;

  /// A later job with the same key replaces this one (Like -> Unlike ->
  /// Like sends one request).
  final String? coalesceKey;
  final OutboxStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;

  OutboxJob copyWith({
    int? id,
    String? endpoint,
    Object? body,
    OutboxStatus? status,
    int? retryCount,
    String? lastError,
  }) => OutboxJob(
    id: id ?? this.id,
    accountId: accountId,
    clientId: clientId,
    entityType: entityType,
    method: method,
    endpoint: endpoint ?? this.endpoint,
    body: body ?? this.body,
    media: media,
    coalesceKey: coalesceKey,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError ?? this.lastError,
    createdAt: createdAt,
  );
}

enum OutboxStatus { pending, failedPermanent }

/// A staged photo or video an outbox job needs: its media id goes in
/// [field] of the request body (a list unless [single]).
class MediaRef {
  const MediaRef({
    required this.localId,
    required this.field,
    this.single = false,
  });

  final String localId;
  final String field;
  final bool single;

  Map<String, Object?> toJson() => {
    'local_id': localId,
    'field': field,
    'single': single,
  };

  static MediaRef fromJson(Map<String, dynamic> j) => MediaRef(
    localId: j['local_id'] as String,
    field: j['field'] as String,
    single: j['single'] == true,
  );
}

/// A picked file copied into the app's own folder (`pending_media`), so the
/// system cannot delete it before it is uploaded.
class PendingMedia {
  const PendingMedia({
    required this.localId,
    required this.accountId,
    required this.localPath,
    required this.purpose,
    this.durationMs,
    this.serverMediaId,
    required this.createdAt,
  });

  final String localId;
  final String accountId;
  final String localPath;

  /// 'post_photo' | 'testimony_photo' | 'testimony_video' | 'profile_photo'
  final String purpose;
  final int? durationMs;

  /// Set once uploaded, so a retry does not upload the bytes again.
  final String? serverMediaId;
  final DateTime createdAt;

  PendingMedia withServerId(String id) => PendingMedia(
    localId: localId,
    accountId: accountId,
    localPath: localPath,
    purpose: purpose,
    durationMs: durationMs,
    serverMediaId: id,
    createdAt: createdAt,
  );
}

/// The phone's offline store: saved API replies (`cache_entries`), the
/// outbox of offline writes (`sync_outbox`), temp-id -> server-id pairs
/// (`id_mappings`) and staged media (`pending_media`). The app uses SQLite
/// ([SqfliteLocalDatabase]); tests and the web use [MemoryLocalDatabase].
abstract class LocalDatabase {
  /// The saved JSON for [key], or null.
  Future<Object?> readCache(String key);

  /// Saves [json] under [key]. [accountId] is null for public data.
  Future<void> writeCache(String key, Object? json, {String? accountId});

  /// Runs [update] over every saved reply of [accountId] whose key passes
  /// [where]; a different (non-identical) result is saved.
  Future<void> updateCaches(
    String accountId,
    Object? Function(String key, Object? json) update, {
    bool Function(String key)? where,
  });

  /// Adds a job. A pending job with the same coalesce key is replaced.
  Future<OutboxJob> enqueue(OutboxJob job);

  /// Pending jobs of [accountId], oldest first.
  Future<List<OutboxJob>> pendingJobs(String accountId);

  /// Jobs the server refused for good (shown so they can be dropped).
  Future<List<OutboxJob>> failedJobs(String accountId);

  Future<void> updateJob(OutboxJob job);
  Future<void> deleteJob(int id);

  Future<void> putMapping(String clientId, String serverId, String entityType);
  Future<Map<String, String>> mappings();

  Future<void> putMedia(PendingMedia media);
  Future<PendingMedia?> getMedia(String localId);
  Future<void> deleteMedia(String localId);

  /// Removes everything saved for [accountId] (sign-out, account deleted)
  /// and returns its staged media, whose files the caller deletes.
  Future<List<PendingMedia>> wipeAccount(String accountId);

  /// Drops replies older than [maxAge] and keeps at most [maxEntries].
  Future<void> prune({
    Duration maxAge = const Duration(days: 30),
    int maxEntries = 3000,
  });
}

/// Nothing survives a restart: tests, and the web build.
class MemoryLocalDatabase implements LocalDatabase {
  final Map<String, ({String? account, String json, DateTime at})> _cache = {};
  final List<OutboxJob> _jobs = [];
  final Map<String, ({String server, String type})> _mappings = {};
  final Map<String, PendingMedia> _media = {};
  int _nextId = 1;

  @override
  Future<Object?> readCache(String key) async {
    final row = _cache[key];
    return row == null ? null : jsonDecode(row.json);
  }

  @override
  Future<void> writeCache(String key, Object? json, {String? accountId}) async {
    _cache[key] = (
      account: accountId,
      json: jsonEncode(json),
      at: DateTime.now(),
    );
  }

  @override
  Future<void> updateCaches(
    String accountId,
    Object? Function(String key, Object? json) update, {
    bool Function(String key)? where,
  }) async {
    for (final key in _cache.keys.toList()) {
      final row = _cache[key]!;
      if (row.account != accountId) continue;
      if (where != null && !where(key)) continue;
      final before = jsonDecode(row.json);
      final after = update(key, before);
      if (!identical(after, before)) {
        _cache[key] = (account: row.account, json: jsonEncode(after), at: row.at);
      }
    }
  }

  @override
  Future<OutboxJob> enqueue(OutboxJob job) async {
    final key = job.coalesceKey;
    if (key != null) {
      _jobs.removeWhere(
        (j) =>
            j.accountId == job.accountId &&
            j.coalesceKey == key &&
            j.status == OutboxStatus.pending,
      );
    }
    _jobs.removeWhere((j) => j.clientId == job.clientId);
    final stored = job.copyWith(id: _nextId++);
    _jobs.add(stored);
    return stored;
  }

  @override
  Future<List<OutboxJob>> pendingJobs(String accountId) async => [
    for (final j in _jobs)
      if (j.accountId == accountId && j.status == OutboxStatus.pending) j,
  ]..sort((a, b) => a.id!.compareTo(b.id!));

  @override
  Future<List<OutboxJob>> failedJobs(String accountId) async => [
    for (final j in _jobs)
      if (j.accountId == accountId && j.status == OutboxStatus.failedPermanent)
        j,
  ];

  @override
  Future<void> updateJob(OutboxJob job) async {
    final i = _jobs.indexWhere((j) => j.id == job.id);
    if (i != -1) _jobs[i] = job;
  }

  @override
  Future<void> deleteJob(int id) async => _jobs.removeWhere((j) => j.id == id);

  @override
  Future<void> putMapping(
    String clientId,
    String serverId,
    String entityType,
  ) async => _mappings[clientId] = (server: serverId, type: entityType);

  @override
  Future<Map<String, String>> mappings() async => {
    for (final e in _mappings.entries) e.key: e.value.server,
  };

  @override
  Future<void> putMedia(PendingMedia media) async =>
      _media[media.localId] = media;

  @override
  Future<PendingMedia?> getMedia(String localId) async => _media[localId];

  @override
  Future<void> deleteMedia(String localId) async => _media.remove(localId);

  @override
  Future<List<PendingMedia>> wipeAccount(String accountId) async {
    _cache.removeWhere((_, row) => row.account == accountId);
    _jobs.removeWhere((j) => j.accountId == accountId);
    final media = [
      for (final m in _media.values)
        if (m.accountId == accountId) m,
    ];
    for (final m in media) {
      _media.remove(m.localId);
    }
    return media;
  }

  @override
  Future<void> prune({
    Duration maxAge = const Duration(days: 30),
    int maxEntries = 3000,
  }) async {
    final cutoff = DateTime.now().subtract(maxAge);
    _cache.removeWhere((_, row) => row.at.isBefore(cutoff));
    if (_cache.length > maxEntries) {
      final oldest = _cache.entries.toList()
        ..sort((a, b) => a.value.at.compareTo(b.value.at));
      for (final e in oldest.take(_cache.length - maxEntries)) {
        _cache.remove(e.key);
      }
    }
  }
}
