import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../connectivity/connectivity_service.dart';
import '../storage/local_database.dart';
import 'token_vault.dart';

/// A failed call to the backend. [status] is 0 when the server could not be
/// reached at all (offline, DNS, timeout).
class ApiException implements Exception {
  const ApiException(
    this.status, {
    this.code,
    this.message,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final int status;

  /// How long the server asks us to wait (`Retry-After`, on a 429).
  final Duration? retryAfter;

  /// The API's machine-readable `code` (for example `username_taken`).
  final String? code;
  final String? message;

  /// Field name (as the API names it, snake_case) -> message, from a 422.
  final Map<String, String> fieldErrors;

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// The signed-in user's tokens. Kept in a [TokenVault] (secure storage) as
/// well as in memory, so a student signs in once and stays signed in until
/// they log out. Without a vault (tests) it is memory only.
class TokenStore {
  TokenStore({this.vault});

  final TokenVault? vault;

  String? accessToken;
  String? refreshToken;

  /// Who the saved tokens belong to, so the app can open without a network.
  String? accountId;
  String? email;

  bool get hasSession => refreshToken != null;

  final List<void Function(String? accountId)> _onCleared = [];

  /// Called when the session ends: sign-out, or the server refusing the
  /// refresh token (the app then goes back to the landing page).
  void addClearListener(void Function(String? accountId) listener) =>
      _onCleared.add(listener);

  void removeClearListener(void Function(String? accountId) listener) =>
      _onCleared.remove(listener);

  /// Loads the saved session at launch. A vault that cannot be read just means
  /// signing in again.
  Future<void> restore() async {
    try {
      final saved = await vault?.read();
      if (saved == null) return;
      accessToken = saved.access;
      refreshToken = saved.refresh;
      accountId = saved.accountId;
      email = saved.email;
    } catch (_) {}
  }

  void save({required String access, required String refresh}) {
    accessToken = access;
    refreshToken = refresh;
    _persist();
  }

  /// Notes whose session this is (after sign-in or sign-up).
  void remember({required String accountId, required String email}) {
    this.accountId = accountId;
    this.email = email;
    _persist();
  }

  void clear() {
    final had = refreshToken != null || accountId != null;
    final account = accountId;
    accessToken = null;
    refreshToken = null;
    accountId = null;
    email = null;
    vault?.clear().catchError((_) {});
    if (had) {
      for (final listener in List.of(_onCleared)) {
        listener(account);
      }
    }
  }

  void _persist() {
    final vault = this.vault;
    final access = accessToken;
    final refresh = refreshToken;
    if (vault == null || access == null || refresh == null) return;
    vault
        .write(
          SavedSession(
            access: access,
            refresh: refresh,
            accountId: accountId,
            email: email,
          ),
        )
        .catchError((_) {});
  }
}

/// Thin JSON client for the FCU API: bearer auth, one automatic token
/// refresh on a 401, and problem+json errors turned into [ApiException].
///
/// With a [cache], every successful GET reply is saved on the phone, and a
/// GET that cannot reach the server (offline, timeout, 5xx) returns the
/// saved reply instead. While [connectivity] already knows the app is
/// offline, a saved reply is returned at once without waiting for the
/// network. Requests that cannot reach the server tell [connectivity].
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? client,
    TokenStore? tokens,
    this.timeout = const Duration(seconds: 20),
    this.cache,
    this.connectivity,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _http = client ?? http.Client(),
       tokens = tokens ?? TokenStore();

  final String baseUrl;
  final TokenStore tokens;
  final Duration timeout;
  final http.Client _http;

  /// Saved GET replies (null: nothing is saved).
  final LocalDatabase? cache;

  /// Told when the server is (un)reachable; asked whether it is.
  final ConnectivityService? connectivity;

  Future<bool>? _refreshing;

  /// Query parameters that change on every call (a clock) and so are left
  /// out of the saved reply's key.
  static const _volatileQuery = {'now'};

  /// Endpoints the API serves without sign-in (landing stories, school and
  /// app-config lookups). Their saved replies are shared by every account
  /// and the signed-out landing/sign-up pages, and survive sign-out.
  static bool isPublicPath(String path) =>
      path.startsWith('/public/') || path.startsWith('/lookups/');

  /// Who saved replies belong to: the signed-in account, or null (public)
  /// for sign-in-free endpoints.
  String? cacheAccount(String path, {bool auth = true}) =>
      auth && !isPublicPath(path) ? tokens.accountId : null;

  /// The key a GET reply is saved under.
  String cacheKey(String path, {Map<String, String>? query, bool auth = true}) {
    final shared = !auth || isPublicPath(path);
    final params = <String>[
      for (final e in (query ?? const <String, String>{}).entries)
        if (!_volatileQuery.contains(e.key)) '${e.key}=${e.value}',
    ]..sort();
    final owner = shared ? 'public' : (tokens.accountId ?? 'anon');
    return '$owner|GET $path${params.isEmpty ? '' : '?${params.join('&')}'}';
  }

  static bool _cacheable(String path) =>
      !path.startsWith('/auth/') && !path.startsWith('/health');

  Future<Object?> _cachedGet(
    String path,
    Map<String, String>? query,
    bool auth,
    Map<String, String>? headers,
  ) async {
    final db = cache!;
    final key = cacheKey(path, query: query, auth: auth);
    if (connectivity?.isOnline == false) {
      final saved = await _readSaved(db, key);
      if (saved != null) return saved.value;
    }
    try {
      final json = await _network('GET', path, query, null, auth, headers);
      final public = !auth || isPublicPath(path);
      final account = cacheAccount(path, auth: auth);
      if (public || account != null) {
        try {
          await db.writeCache(key, json, accountId: account);
        } catch (_) {}
      }
      return json;
    } on ApiException catch (e) {
      if (e.isNetwork || e.status >= 500) {
        final saved = await _readSaved(db, key);
        if (saved != null) return saved.value;
      }
      rethrow;
    }
  }

  static Future<({Object? value})?> _readSaved(
    LocalDatabase db,
    String key,
  ) async {
    try {
      final saved = await db.readCache(key);
      return saved == null ? null : (value: saved);
    } catch (_) {
      return null;
    }
  }

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      send('GET', path, query: query);

  Future<Object?> post(
    String path, {
    Object? body,
    bool auth = true,
    Map<String, String>? headers,
  }) => send('POST', path, body: body, auth: auth, headers: headers);

  Future<Object?> put(String path, {Object? body}) =>
      send('PUT', path, body: body);

  Future<Object?> patch(String path, {Object? body}) =>
      send('PATCH', path, body: body);

  Future<Object?> delete(String path) => send('DELETE', path);

  /// Follows `next_cursor` and returns every item of a paginated list
  /// (at most [maxPages] pages of 100).
  Future<List<Map<String, dynamic>>> getAllItems(
    String path, {
    Map<String, String>? query,
    int maxPages = 10,
  }) async {
    final all = <Map<String, dynamic>>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final json = await get(
        path,
        query: {...?query, 'limit': '100', 'cursor': ?cursor},
      );
      if (json is! Map<String, dynamic>) break;
      all.addAll(itemsOf(json));
      cursor = json['next_cursor'] as String?;
      if (cursor == null) break;
    }
    return all;
  }

  /// Returns the decoded JSON body, or null for an empty body (204/202).
  Future<Object?> send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
    Map<String, String>? headers,
  }) async {
    if (method == 'GET' && cache != null && _cacheable(path)) {
      return _cachedGet(path, query, auth, headers);
    }
    return _network(method, path, query, body, auth, headers);
  }

  Future<Object?> _network(
    String method,
    String path,
    Map<String, String>? query,
    Object? body,
    bool auth,
    Map<String, String>? headers,
  ) async {
    var response = await _once(method, path, query, body, auth, headers);
    if (response.statusCode == 401 && auth && tokens.hasSession) {
      if (await _refresh()) {
        response = await _once(method, path, query, body, auth, headers);
      }
    }
    return _decode(response);
  }

  Future<http.Response> _once(
    String method,
    String path,
    Map<String, String>? query,
    Object? body,
    bool auth, [
    Map<String, String>? headers,
  ]) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (headers != null) request.headers.addAll(headers);
    final access = tokens.accessToken;
    if (auth && access != null) {
      request.headers['Authorization'] = 'Bearer $access';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);
      if (response.statusCode < 500) connectivity?.reportReachable();
      return response;
    } catch (_) {
      connectivity?.reportUnreachable();
      throw const ApiException(0, message: 'Could not reach the server');
    }
  }

  /// Swaps the refresh token for a new pair, as a 401 would (the realtime
  /// socket calls it on a 4401 close). False when there is no session, the
  /// server refused it (tokens cleared) or the server can't be reached.
  Future<bool> refreshSession() => _refresh();

  /// One refresh at a time; concurrent 401s share it.
  Future<bool> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final response = await _once('POST', '/auth/refresh', null, {
        'refresh_token': refresh,
      }, false);
      if (response.statusCode == 401) {
        tokens.clear(); // the server no longer accepts it: signed out
        return false;
      }
      if (response.statusCode != 200) {
        return false; // a server hiccup: keep the session and try again later
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) {
        tokens.clear();
        return false;
      }
      tokens.save(
        access: json['access_token'] as String,
        refresh: json['refresh_token'] as String,
      );
      return true;
    } on ApiException {
      return false; // offline: keep the tokens and try again later
    } catch (_) {
      tokens.clear();
      return false;
    }
  }

  Object? _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    Object? json;
    if (text.isNotEmpty) {
      try {
        json = jsonDecode(text);
      } catch (_) {
        json = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    var code = 'http_${response.statusCode}';
    String? message;
    final fields = <String, String>{};
    if (json is Map<String, dynamic>) {
      code = (json['code'] as String?) ?? code;
      message = (json['detail'] as String?) ?? (json['title'] as String?);
      final errors = json['errors'];
      if (errors is List) {
        for (final e in errors) {
          if (e is Map<String, dynamic> && e['field'] is String) {
            fields.putIfAbsent(
              e['field'] as String,
              () => (e['message'] as String?) ?? 'Invalid',
            );
          }
        }
      }
    }
    final retry = int.tryParse(response.headers['retry-after'] ?? '');
    throw ApiException(
      response.statusCode,
      code: code,
      message: message,
      fieldErrors: fields,
      retryAfter: retry == null ? null : Duration(seconds: retry),
    );
  }

  void close() => _http.close();
}

/// The `items` array of a list response, as maps.
List<Map<String, dynamic>> itemsOf(Object? json) {
  if (json is Map<String, dynamic> && json['items'] is List) {
    return (json['items'] as List).whereType<Map<String, dynamic>>().toList();
  }
  return <Map<String, dynamic>>[]; // growable: callers sort in place
}

/// A nested JSON object, or null.
Map<String, dynamic>? objectOf(Object? json) =>
    json is Map<String, dynamic> ? json : null;
