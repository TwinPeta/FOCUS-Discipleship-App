import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

/// [LocalDatabase] in SQLite (`fcu_offline.db`), so saved content and
/// offline writes survive the app being closed.
class SqfliteLocalDatabase implements LocalDatabase {
  SqfliteLocalDatabase._(this._db);

  final Database _db;

  static Future<SqfliteLocalDatabase> open({String name = 'fcu_offline.db'}) async {
    final path = p.join(await getDatabasesPath(), name);
    final db = await openDatabase(
      path,
      version: 1,
      // WAL: writes (saving replies while scrolling) do not block reads.
      // Incremental auto-vacuum (only takes effect on a new file) lets the
      // file shrink after [prune].
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
        await db.execute('PRAGMA auto_vacuum = INCREMENTAL');
      },
      onCreate: (db, _) async {
        final batch = db.batch()
          ..execute('''
            CREATE TABLE cache_entries (
              cache_key TEXT PRIMARY KEY,
              account_id TEXT,
              payload_json TEXT NOT NULL,
              updated_at INTEGER NOT NULL,
              etag TEXT
            )''')
          ..execute(
            'CREATE INDEX idx_cache_account ON cache_entries(account_id)',
          )
          ..execute(
            'CREATE INDEX idx_cache_updated ON cache_entries(updated_at)',
          )
          ..execute('''
            CREATE TABLE sync_outbox (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              account_id TEXT NOT NULL,
              client_id TEXT NOT NULL UNIQUE,
              entity_type TEXT NOT NULL,
              operation TEXT NOT NULL,
              endpoint TEXT NOT NULL,
              payload_json TEXT,
              media_refs_json TEXT,
              coalesce_key TEXT,
              status TEXT NOT NULL DEFAULT 'pending',
              retry_count INTEGER NOT NULL DEFAULT 0,
              last_error TEXT,
              created_at INTEGER NOT NULL
            )''')
          ..execute(
            'CREATE INDEX idx_outbox_account_status '
            'ON sync_outbox(account_id, status, id)',
          )
          ..execute(
            'CREATE INDEX idx_outbox_coalesce '
            'ON sync_outbox(account_id, coalesce_key)',
          )
          ..execute('''
            CREATE TABLE id_mappings (
              client_id TEXT PRIMARY KEY,
              server_id TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )''')
          ..execute('''
            CREATE TABLE pending_media (
              local_id TEXT PRIMARY KEY,
              account_id TEXT NOT NULL,
              local_path TEXT NOT NULL,
              purpose TEXT NOT NULL,
              duration_ms INTEGER,
              server_media_id TEXT,
              created_at INTEGER NOT NULL
            )''');
        await batch.commit(noResult: true);
      },
    );
    return SqfliteLocalDatabase._(db);
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<Object?> readCache(String key) async {
    final rows = await _db.query(
      'cache_entries',
      columns: ['payload_json'],
      where: 'cache_key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload_json'] as String);
  }

  @override
  Future<void> writeCache(String key, Object? json, {String? accountId}) =>
      _db.insert('cache_entries', {
        'cache_key': key,
        'account_id': accountId,
        'payload_json': jsonEncode(json),
        'updated_at': _now(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> updateCaches(
    String accountId,
    Object? Function(String key, Object? json) update, {
    bool Function(String key)? where,
  }) async {
    final rows = await _db.query(
      'cache_entries',
      columns: ['cache_key', 'payload_json'],
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    final batch = _db.batch();
    var changed = false;
    for (final row in rows) {
      final key = row['cache_key'] as String;
      if (where != null && !where(key)) continue;
      final before = jsonDecode(row['payload_json'] as String);
      final after = update(key, before);
      if (identical(after, before)) continue;
      changed = true;
      batch.update(
        'cache_entries',
        {'payload_json': jsonEncode(after)},
        where: 'cache_key = ?',
        whereArgs: [key],
      );
    }
    if (changed) await batch.commit(noResult: true);
  }

  OutboxJob _job(Map<String, Object?> r) {
    final payload = r['payload_json'] as String?;
    final media = r['media_refs_json'] as String?;
    return OutboxJob(
      id: r['id'] as int,
      accountId: r['account_id'] as String,
      clientId: r['client_id'] as String,
      entityType: r['entity_type'] as String,
      method: r['operation'] as String,
      endpoint: r['endpoint'] as String,
      body: payload == null ? null : jsonDecode(payload),
      media: media == null
          ? const []
          : [
              for (final m in jsonDecode(media) as List)
                MediaRef.fromJson(m as Map<String, dynamic>),
            ],
      coalesceKey: r['coalesce_key'] as String?,
      status: r['status'] == 'failed_permanent'
          ? OutboxStatus.failedPermanent
          : OutboxStatus.pending,
      retryCount: (r['retry_count'] as int?) ?? 0,
      lastError: r['last_error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    );
  }

  static String _status(OutboxStatus s) =>
      s == OutboxStatus.failedPermanent ? 'failed_permanent' : 'pending';

  @override
  Future<OutboxJob> enqueue(OutboxJob job) async {
    final id = await _db.transaction((txn) async {
      if (job.coalesceKey != null) {
        await txn.delete(
          'sync_outbox',
          where: 'account_id = ? AND coalesce_key = ? AND status = ?',
          whereArgs: [job.accountId, job.coalesceKey, 'pending'],
        );
      }
      return txn.insert('sync_outbox', {
        'account_id': job.accountId,
        'client_id': job.clientId,
        'entity_type': job.entityType,
        'operation': job.method,
        'endpoint': job.endpoint,
        'payload_json': job.body == null ? null : jsonEncode(job.body),
        'media_refs_json': job.media.isEmpty
            ? null
            : jsonEncode([for (final m in job.media) m.toJson()]),
        'coalesce_key': job.coalesceKey,
        'status': _status(job.status),
        'retry_count': job.retryCount,
        'last_error': job.lastError,
        'created_at': job.createdAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    return job.copyWith(id: id);
  }

  Future<List<OutboxJob>> _jobs(String accountId, String status) async {
    final rows = await _db.query(
      'sync_outbox',
      where: 'account_id = ? AND status = ?',
      whereArgs: [accountId, status],
      orderBy: 'id ASC',
    );
    return rows.map(_job).toList();
  }

  @override
  Future<List<OutboxJob>> pendingJobs(String accountId) =>
      _jobs(accountId, 'pending');

  @override
  Future<List<OutboxJob>> failedJobs(String accountId) =>
      _jobs(accountId, 'failed_permanent');

  @override
  Future<void> updateJob(OutboxJob job) => _db.update(
    'sync_outbox',
    {
      'endpoint': job.endpoint,
      'payload_json': job.body == null ? null : jsonEncode(job.body),
      'status': _status(job.status),
      'retry_count': job.retryCount,
      'last_error': job.lastError,
    },
    where: 'id = ?',
    whereArgs: [job.id],
  );

  @override
  Future<void> deleteJob(int id) =>
      _db.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> putMapping(String clientId, String serverId, String entityType) =>
      _db.insert('id_mappings', {
        'client_id': clientId,
        'server_id': serverId,
        'entity_type': entityType,
        'created_at': _now(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<Map<String, String>> mappings() async {
    final rows = await _db.query('id_mappings');
    return {
      for (final r in rows) r['client_id'] as String: r['server_id'] as String,
    };
  }

  PendingMedia _media(Map<String, Object?> r) => PendingMedia(
    localId: r['local_id'] as String,
    accountId: r['account_id'] as String,
    localPath: r['local_path'] as String,
    purpose: r['purpose'] as String,
    durationMs: r['duration_ms'] as int?,
    serverMediaId: r['server_media_id'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
  );

  @override
  Future<void> putMedia(PendingMedia m) => _db.insert('pending_media', {
    'local_id': m.localId,
    'account_id': m.accountId,
    'local_path': m.localPath,
    'purpose': m.purpose,
    'duration_ms': m.durationMs,
    'server_media_id': m.serverMediaId,
    'created_at': m.createdAt.millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<PendingMedia?> getMedia(String localId) async {
    final rows = await _db.query(
      'pending_media',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    return rows.isEmpty ? null : _media(rows.first);
  }

  @override
  Future<void> deleteMedia(String localId) =>
      _db.delete('pending_media', where: 'local_id = ?', whereArgs: [localId]);

  @override
  Future<List<PendingMedia>> wipeAccount(String accountId) async {
    final media = (await _db.query(
      'pending_media',
      where: 'account_id = ?',
      whereArgs: [accountId],
    )).map(_media).toList();
    await _db.transaction((txn) async {
      for (final table in ['cache_entries', 'sync_outbox', 'pending_media']) {
        await txn.delete(table, where: 'account_id = ?', whereArgs: [accountId]);
      }
    });
    return media;
  }

  @override
  Future<void> prune({
    Duration maxAge = const Duration(days: 30),
    int maxEntries = 3000,
  }) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    await _db.delete(
      'cache_entries',
      where: 'updated_at < ?',
      whereArgs: [cutoff],
    );
    await _db.execute(
      'DELETE FROM cache_entries WHERE cache_key NOT IN '
      '(SELECT cache_key FROM cache_entries ORDER BY updated_at DESC LIMIT ?)',
      [maxEntries],
    );
    // Give the freed pages back to the phone (no-op on an older file
    // without auto-vacuum).
    await _db.execute('PRAGMA incremental_vacuum');
  }
}
