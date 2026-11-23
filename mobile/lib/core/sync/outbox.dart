import 'dart:async';
import 'dart:convert';

import '../connectivity/connectivity_service.dart';
import '../network/api_client.dart';
import '../network/media_uploader.dart';
import '../storage/local_database.dart';
import '../storage/media_stash.dart';

/// A photo or video picked for a write. Its media id goes in [field] of the
/// request body (a list unless [single]).
class LocalMedia {
  const LocalMedia({
    required this.path,
    required this.purpose,
    this.field = 'media_ids',
    this.single = false,
    this.duration,
  });

  final String path;

  /// 'post_photo' | 'testimony_photo' | 'testimony_video' | 'profile_photo'
  final String purpose;
  final String field;
  final bool single;

  /// Videos only.
  final Duration? duration;
}

/// A write that may be saved for later when the server cannot be reached.
class OfflineWrite {
  const OfflineWrite({
    required this.method,
    required this.endpoint,
    required this.entityType,
    required this.clientId,
    this.body,
    this.coalesceKey,
    this.media = const [],
    this.creates = false,
    this.optimistic,
    this.patch,
    this.patchWhere,
  });

  final String method;
  final String endpoint;
  final Map<String, dynamic>? body;
  final String entityType;

  /// The `Idempotency-Key`; for a create, the temporary id of the new item.
  final String clientId;

  /// Rapid toggles of the same thing (likes, "I prayed") keep only the
  /// latest.
  final String? coalesceKey;
  final List<LocalMedia> media;

  /// The request creates an item whose server id replaces [clientId] in
  /// later queued requests (a comment on a post made offline).
  final bool creates;

  /// What the request is expected to return, in the API's shape: returned
  /// to the caller when the write is saved for later.
  final Object? optimistic;

  /// Applied to the saved replies (see `json_patch.dart`) when the write is
  /// saved for later, so the change shows offline too.
  final Object? Function(String key, Object? json)? patch;

  /// Which saved replies [patch] looks at (all of the account's if null).
  final bool Function(String key)? patchWhere;
}

/// The result of [Outbox.write]: the server's reply, or [OfflineWrite.optimistic]
/// when the write was [queued].
class WriteResult {
  const WriteResult(this.json, {required this.queued});
  final Object? json;
  final bool queued;
}

/// What a [Outbox.drain] did.
class DrainResult {
  const DrainResult({this.sent = 0, this.failed = 0, this.stopped = false});
  final int sent;

  /// Refused by the server for good (kept as failed, not retried).
  final int failed;

  /// Stopped early (offline again, server trouble): the rest waits.
  final bool stopped;
}

/// Writes go straight to the server when it can be reached. Otherwise (or
/// while older writes are still waiting, so the order is kept) they are
/// saved in the outbox with their photos copied into the app's folder, the
/// saved replies are patched so the change shows at once, and [drain] sends
/// them later, oldest first, each with its `Idempotency-Key`.
///
/// Without a [db] (tests), every write goes straight to the server.
class Outbox {
  Outbox({
    required this.api,
    this.db,
    this.uploader,
    this.connectivity,
    this.stash = const MediaStash(),
  });

  final ApiClient api;
  final LocalDatabase? db;
  final MediaUploader? uploader;
  final ConnectivityService? connectivity;
  final MediaStash stash;

  final _changes = StreamController<void>.broadcast();
  Future<DrainResult>? _draining;
  int _seq = 0;

  /// Fires when a write is queued or the queue changes after a drain.
  Stream<void> get changes => _changes.stream;

  String? get _account => api.tokens.accountId;

  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Writes waiting to be sent for the signed-in account.
  Future<int> pendingCount() async {
    final db = this.db;
    final account = _account;
    if (db == null || account == null) return 0;
    try {
      return (await db.pendingJobs(account)).length;
    } catch (_) {
      return 0;
    }
  }

  /// Writes the server refused for good.
  Future<List<OutboxJob>> failedJobs() async {
    final db = this.db;
    final account = _account;
    if (db == null || account == null) return const [];
    return db.failedJobs(account);
  }

  /// Forgets a failed write, and its staged photos.
  Future<void> dismiss(OutboxJob job) async {
    final db = this.db;
    if (db == null) return;
    await db.deleteJob(job.id!);
    await _dropMedia(db, job);
    _changed();
  }

  Future<WriteResult> write(OfflineWrite w) async {
    final db = this.db;
    final account = _account;
    if (db == null || account == null) {
      return WriteResult(await _direct(w, w.endpoint, w.body), queued: false);
    }
    final mappings = await _mappings(db);
    final endpoint = _resolve(w.endpoint, mappings);
    final body = _resolveJson(w.body, mappings) as Map<String, dynamic>?;
    final online = connectivity?.isOnline ?? true;
    final waiting = (await db.pendingJobs(account)).isNotEmpty;
    if (online && !waiting) {
      try {
        return WriteResult(await _direct(w, endpoint, body), queued: false);
      } on ApiException catch (e) {
        if (!e.isNetwork) rethrow;
      }
    }
    await _queue(db, account, w, endpoint, body);
    return WriteResult(w.optimistic, queued: true);
  }

  Future<Map<String, String>> _mappings(LocalDatabase db) async {
    try {
      return await db.mappings();
    } catch (_) {
      return const {};
    }
  }

  static String _resolve(String text, Map<String, String> mappings) {
    var out = text;
    for (final e in mappings.entries) {
      if (out.contains(e.key)) out = out.replaceAll(e.key, e.value);
    }
    return out;
  }

  static Object? _resolveJson(Object? json, Map<String, String> mappings) {
    if (json == null || mappings.isEmpty) return json;
    final text = jsonEncode(json);
    final resolved = _resolve(text, mappings);
    return identical(text, resolved) || text == resolved
        ? json
        : jsonDecode(resolved);
  }

  Future<String> _upload(String path, String purpose, int? durationMs) {
    final uploader = this.uploader;
    if (uploader == null) {
      throw const ApiException(500, message: 'Uploads are not available');
    }
    if (purpose == 'testimony_video') {
      return uploader.uploadVideo(
        path,
        duration: Duration(milliseconds: durationMs ?? 0),
      );
    }
    return uploader.uploadPhoto(path, purpose: purpose);
  }

  static void _put(Map<String, dynamic> body, String field, bool single, String id) {
    if (single) {
      body[field] = id;
    } else {
      body[field] = [...((body[field] as List?) ?? const []), id];
    }
  }

  Future<Object?> _direct(
    OfflineWrite w,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    final sent = body == null ? null : Map<String, dynamic>.of(body);
    if (w.media.isNotEmpty) {
      final target = sent ?? <String, dynamic>{};
      for (final m in w.media) {
        _put(
          target,
          m.field,
          m.single,
          await _upload(m.path, m.purpose, m.duration?.inMilliseconds),
        );
      }
      return api.send(
        w.method,
        endpoint,
        body: target,
        headers: {'Idempotency-Key': w.clientId},
      );
    }
    return api.send(
      w.method,
      endpoint,
      body: sent,
      headers: {'Idempotency-Key': w.clientId},
    );
  }

  Future<void> _queue(
    LocalDatabase db,
    String account,
    OfflineWrite w,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    // A newer write replaces a waiting one with the same key (see
    // [OfflineWrite.coalesceKey]): the replaced one's staged photos go too.
    final key = w.coalesceKey;
    if (key != null) {
      for (final old in await db.pendingJobs(account)) {
        if (old.coalesceKey == key) await _dropMedia(db, old);
      }
    }
    final refs = <MediaRef>[];
    final now = DateTime.now();
    for (final m in w.media) {
      final localId = 'media-${now.microsecondsSinceEpoch}-${_seq++}';
      final kept = await stash.keep(m.path, localId);
      await db.putMedia(
        PendingMedia(
          localId: localId,
          accountId: account,
          localPath: kept,
          purpose: m.purpose,
          durationMs: m.duration?.inMilliseconds,
          createdAt: now,
        ),
      );
      refs.add(MediaRef(localId: localId, field: m.field, single: m.single));
    }
    await db.enqueue(
      OutboxJob(
        accountId: account,
        clientId: w.clientId,
        entityType: w.creates ? '${w.entityType}:create' : w.entityType,
        method: w.method,
        endpoint: endpoint,
        body: body,
        media: refs,
        coalesceKey: w.coalesceKey,
        createdAt: now,
      ),
    );
    final patch = w.patch;
    if (patch != null) {
      try {
        await db.updateCaches(account, patch, where: w.patchWhere);
      } catch (_) {}
    }
    _changed();
  }

  /// Sends the queued writes, oldest first. One drain at a time: a second
  /// call while one runs gets the same result.
  Future<DrainResult> drain() =>
      _draining ??= _drain().whenComplete(() => _draining = null);

  Future<DrainResult> _drain() async {
    final db = this.db;
    final account = _account;
    if (db == null || account == null) return const DrainResult();
    var sent = 0;
    var failed = 0;
    var stopped = false;
    final jobs = await db.pendingJobs(account);
    for (final job in jobs) {
      if (_account != account) {
        stopped = true; // signed out meanwhile
        break;
      }
      final mappings = await _mappings(db);
      final endpoint = _resolve(job.endpoint, mappings);
      var body = _resolveJson(job.body, mappings) as Map<String, dynamic>?;
      try {
        if (job.media.isNotEmpty) {
          body = Map<String, dynamic>.of(body ?? const {});
          for (final ref in job.media) {
            final media = await db.getMedia(ref.localId);
            if (media == null) {
              throw const ApiException(422, message: 'The photo is gone');
            }
            var id = media.serverMediaId;
            if (id == null) {
              id = await _upload(
                media.localPath,
                media.purpose,
                media.durationMs,
              );
              await db.putMedia(media.withServerId(id));
            }
            _put(body, ref.field, ref.single, id);
          }
        }
        final json = await api.send(
          job.method,
          endpoint,
          body: body,
          headers: {'Idempotency-Key': job.clientId},
        );
        final serverId = json is Map<String, dynamic> ? json['id'] : null;
        if (job.entityType.endsWith(':create') &&
            serverId is String &&
            serverId != job.clientId) {
          await db.putMapping(job.clientId, serverId, job.entityType);
        }
        await db.deleteJob(job.id!);
        await _dropMedia(db, job);
        sent++;
      } on ApiException catch (e) {
        final retry =
            e.isNetwork || e.status >= 500 || e.status == 429 || e.status == 401;
        if (retry) {
          await db.updateJob(
            job.copyWith(
              retryCount: job.retryCount + 1,
              lastError: e.message ?? e.code,
            ),
          );
          stopped = true;
          break;
        }
        await db.updateJob(
          job.copyWith(
            status: OutboxStatus.failedPermanent,
            lastError: e.message ?? e.code ?? 'Refused (${e.status})',
          ),
        );
        failed++;
      } catch (e) {
        // A staged file that cannot be read: it will never send.
        await db.updateJob(
          job.copyWith(
            status: OutboxStatus.failedPermanent,
            lastError: '$e',
          ),
        );
        failed++;
      }
    }
    if (sent > 0 || failed > 0) _changed();
    return DrainResult(sent: sent, failed: failed, stopped: stopped);
  }

  Future<void> _dropMedia(LocalDatabase db, OutboxJob job) async {
    for (final ref in job.media) {
      final media = await db.getMedia(ref.localId);
      if (media != null) await stash.discard(media.localPath);
      await db.deleteMedia(ref.localId);
    }
  }

  /// Removes everything saved on the phone for [accountId]: saved replies,
  /// queued writes and their staged files.
  Future<void> wipe(String accountId) async {
    final db = this.db;
    if (db == null) return;
    try {
      for (final media in await db.wipeAccount(accountId)) {
        await stash.discard(media.localPath);
      }
    } catch (_) {}
    _changed();
  }

  void dispose() => _changes.close();
}

/// The path of a saved GET reply's key (`account|GET /path?query`).
String? cachedPathOf(String key) {
  final at = key.indexOf('|GET ');
  if (at == -1) return null;
  final rest = key.substring(at + 5);
  final q = rest.indexOf('?');
  return q == -1 ? rest : rest.substring(0, q);
}

/// Saved first pages of the list at [path] (later pages are left alone).
bool Function(String key) firstPageOf(String path) =>
    (key) => cachedPathOf(key) == path && !key.contains('cursor=');

/// A UTC timestamp in the API's format.
String apiNow() => DateTime.now().toUtc().toIso8601String();
