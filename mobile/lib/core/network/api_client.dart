import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A failed call to the backend. [status] is 0 when the server could not be
/// reached at all (offline, DNS, timeout).
class ApiException implements Exception {
  const ApiException(
    this.status, {
    this.code,
    this.message,
    this.fieldErrors = const {},
  });

  final int status;

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

/// The signed-in user's tokens. Held in memory only (the app has no secure
/// storage yet, by decision), so closing the app signs the user out.
class TokenStore {
  String? accessToken;
  String? refreshToken;

  bool get hasSession => refreshToken != null;

  void save({required String access, required String refresh}) {
    accessToken = access;
    refreshToken = refresh;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}

/// Thin JSON client for the FCU API: bearer auth, one automatic token
/// refresh on a 401, and problem+json errors turned into [ApiException].
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? client,
    TokenStore? tokens,
    this.timeout = const Duration(seconds: 20),
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _http = client ?? http.Client(),
       tokens = tokens ?? TokenStore();

  final String baseUrl;
  final TokenStore tokens;
  final Duration timeout;
  final http.Client _http;

  Future<bool>? _refreshing;

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
      return await http.Response.fromStream(streamed).timeout(timeout);
    } catch (_) {
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
      if (response.statusCode != 200) {
        tokens.clear();
        return false;
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
    throw ApiException(
      response.statusCode,
      code: code,
      message: message,
      fieldErrors: fields,
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
