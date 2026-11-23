import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Online/offline status of the app's backend.
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onlineChanges;

  /// Re-checks the connection (the banner's Retry). Returns the new state.
  Future<bool> check();

  /// A request could not reach the server: switch to offline at once
  /// instead of waiting for the next check.
  void reportUnreachable();

  /// A request got an answer from the server: it is reachable.
  void reportReachable();
}

/// Online means "the FCU API answers". It asks the API's public health
/// endpoint at start, every [interval], whenever the phone's network
/// changes and whenever [check] is called, so the banner also appears when
/// the phone has a signal but the server cannot be reached. Losing the
/// network (no Wi-Fi or mobile data) switches to offline at once, and so
/// does any request that cannot reach the server.
class ApiConnectivityService implements ConnectivityService {
  ApiConnectivityService({
    required this._healthUrl,
    http.Client? client,
    Duration interval = const Duration(seconds: 20),
    this._timeout = const Duration(seconds: 3),
    Stream<bool>? linkChanges,
    bool checkNow = true,
  }) : _client = client ?? http.Client() {
    _timer = Timer.periodic(interval, (_) => unawaited(check()));
    _links = linkChanges?.listen(_onLink);
    if (checkNow) unawaited(check());
  }

  final Uri _healthUrl;
  final http.Client _client;
  final Duration _timeout;
  late final Timer _timer;
  StreamSubscription<bool>? _links;
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;
  bool _hasLink = true;
  Future<bool>? _checking;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  void _set(bool online) {
    if (online == _online) return;
    _online = online;
    if (!_controller.isClosed) _controller.add(online);
  }

  void _onLink(bool hasLink) {
    _hasLink = hasLink;
    if (!hasLink) {
      _set(false);
    } else {
      unawaited(check());
    }
  }

  @override
  Future<bool> check() => _checking ??= _check().whenComplete(
    () => _checking = null,
  );

  Future<bool> _check() async {
    if (!_hasLink) {
      _set(false);
      return false;
    }
    var online = true;
    try {
      final response = await _client.get(_healthUrl).timeout(_timeout);
      online = response.statusCode < 500;
    } catch (_) {
      online = false;
    }
    _set(online);
    return _online;
  }

  @override
  void reportUnreachable() => _set(false);

  @override
  void reportReachable() {
    if (_hasLink) _set(true);
  }

  void dispose() {
    _timer.cancel();
    _links?.cancel();
    _client.close();
    _controller.close();
  }
}

/// Whether the phone has any network link (Wi-Fi, mobile data, ethernet,
/// VPN), from the operating system.
Stream<bool> osLinkChanges() => Connectivity().onConnectivityChanged.map(
  (results) => results.any((r) => r != ConnectivityResult.none),
);

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  Stream<bool>? links;
  try {
    links = osLinkChanges();
  } catch (_) {
    links = null; // no plugin (tests, unsupported platform): health only
  }
  final service = ApiConnectivityService(
    healthUrl: Uri.parse('${ApiConfig.baseUrl}/health'),
    linkChanges: links,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// True while online. Screens show [OfflineBanner] when this is false.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield service.isOnline;
  yield* service.onlineChanges;
});
