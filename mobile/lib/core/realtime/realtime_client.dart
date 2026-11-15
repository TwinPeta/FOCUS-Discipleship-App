import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/api_client.dart';

/// One server push: `{event, data, at}` (see `api/src/realtime/socket.js`).
class RealtimeEvent {
  const RealtimeEvent(this.name, this.data, this.at);

  final String name;
  final Map<String, dynamic> data;
  final DateTime at;

  /// Null for a frame that is not a JSON object with a string `event`.
  static RealtimeEvent? tryParse(Object? frame) {
    if (frame is! String) return null;
    Object? json;
    try {
      json = jsonDecode(frame);
    } catch (_) {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    final name = json['event'];
    if (name is! String) return null;
    final data = json['data'];
    return RealtimeEvent(
      name,
      data is Map<String, dynamic> ? data : const {},
      DateTime.tryParse((json['at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

/// `<base>/realtime?token=...`, with http(s) turned into ws(s). [baseUrl]
/// already ends in `/v1`.
Uri realtimeUri(String baseUrl, String token) {
  final base = Uri.parse(
    baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
  );
  final scheme = switch (base.scheme) {
    'https' || 'wss' => 'wss',
    _ => 'ws',
  };
  return base.replace(
    scheme: scheme,
    path: '${base.path}/realtime',
    queryParameters: {'token': token},
  );
}

/// The socket as the client needs it; [WebSocketRealtimeChannel] wraps a real
/// one and tests pass a fake.
abstract class RealtimeChannel {
  Stream<dynamic> get stream;

  /// The close code once [stream] is done (4401 = bad token).
  int? get closeCode;

  Future<void> close();
}

class WebSocketRealtimeChannel implements RealtimeChannel {
  WebSocketRealtimeChannel(Uri uri) : _channel = WebSocketChannel.connect(uri);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  int? get closeCode => _channel.closeCode;

  @override
  Future<void> close() async => _channel.sink.close();
}

typedef RealtimeConnect = RealtimeChannel Function(Uri uri);
typedef RealtimeDelay = Future<void> Function(Duration wait);

/// Live updates from the server. [start] while signed in, [stop] on sign-out.
abstract class RealtimeClient {
  Stream<RealtimeEvent> get events;

  void start();

  Future<void> stop();

  void dispose();
}

/// Used when the API is off: never connects, never emits.
class NoopRealtimeClient implements RealtimeClient {
  @override
  Stream<RealtimeEvent> get events => const Stream.empty();

  @override
  void start() {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

/// The close code the server uses for a missing or expired token.
const realtimeUnauthorizedCode = 4401;

/// Waits between reconnect attempts; the last one repeats.
const realtimeBackoff = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 30),
];

/// Connects to `wss://<host>/v1/realtime?token=<access>` with the
/// [ApiClient]'s token, and reconnects with [realtimeBackoff] while started.
/// On a 4401 close it refreshes the token once through the ApiClient, then
/// reconnects; a second 4401 in a row stops it until the next [start].
class SocketRealtimeClient implements RealtimeClient {
  SocketRealtimeClient({
    required this.api,
    RealtimeConnect? connect,
    RealtimeDelay? delay,
  }) : _connect = connect ?? WebSocketRealtimeChannel.new,
       _delay = delay ?? Future<void>.delayed;

  final ApiClient api;
  final RealtimeConnect _connect;
  final RealtimeDelay _delay;
  final _events = StreamController<RealtimeEvent>.broadcast();

  bool _running = false;
  int _generation = 0;
  int _attempt = 0;
  bool _refreshed = false;
  RealtimeChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  bool get isRunning => _running;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  void start() {
    if (_running) return;
    _running = true;
    _attempt = 0;
    _refreshed = false;
    _open();
  }

  void _open() {
    if (!_running) return;
    final token = api.tokens.accessToken;
    if (token == null) {
      _running = false; // signed out underneath us
      return;
    }
    final generation = ++_generation;
    final RealtimeChannel channel;
    try {
      channel = _connect(realtimeUri(api.baseUrl, token));
    } catch (_) {
      unawaited(_closed(generation, null));
      return;
    }
    _channel = channel;
    _sub = channel.stream.listen(
      (frame) {
        _attempt = 0;
        _refreshed = false;
        final event = RealtimeEvent.tryParse(frame);
        if (event != null && !_events.isClosed) _events.add(event);
      },
      onError: (Object _) {},
      onDone: () => _closed(generation, channel.closeCode),
    );
  }

  Future<void> _closed(int generation, int? code) async {
    if (!_running || generation != _generation) return;
    _channel = null;
    _sub = null;
    if (code == realtimeUnauthorizedCode) {
      if (_refreshed) {
        _running = false;
        return;
      }
      _refreshed = true;
      final ok = await api.refreshSession();
      if (!_running || generation != _generation) return;
      if (ok) {
        _open();
        return;
      }
    }
    final wait =
        realtimeBackoff[_attempt < realtimeBackoff.length
            ? _attempt
            : realtimeBackoff.length - 1];
    _attempt++;
    await _delay(wait);
    if (!_running || generation != _generation) return;
    _open();
  }

  @override
  Future<void> stop() async {
    _running = false;
    _generation++;
    final channel = _channel;
    _channel = null;
    await _sub?.cancel();
    _sub = null;
    await channel?.close();
  }

  @override
  void dispose() {
    unawaited(stop());
    unawaited(_events.close());
  }
}
