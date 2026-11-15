import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Online/offline status of the app's backend.
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onlineChanges;

  /// Re-checks the connection (the banner's Retry). Returns the new state.
  Future<bool> check();
}

/// Online means "the FCU API answers". It asks the API's public health
/// endpoint every [interval] and whenever [check] is called, so the banner
/// also appears when the phone has a signal but the server cannot be reached.
class ApiConnectivityService implements ConnectivityService {
  ApiConnectivityService({
    required this._healthUrl,
    http.Client? client,
    Duration interval = const Duration(seconds: 20),
    this._timeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client() {
    _timer = Timer.periodic(interval, (_) => unawaited(check()));
  }

  final Uri _healthUrl;
  final http.Client _client;
  final Duration _timeout;
  late final Timer _timer;
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  @override
  Future<bool> check() async {
    var online = true;
    try {
      final response = await _client.get(_healthUrl).timeout(_timeout);
      online = response.statusCode < 500;
    } catch (_) {
      online = false;
    }
    if (online != _online) {
      _online = online;
      if (!_controller.isClosed) _controller.add(online);
    }
    return _online;
  }

  void dispose() {
    _timer.cancel();
    _client.close();
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ApiConnectivityService(
    healthUrl: Uri.parse('${ApiConfig.baseUrl}/health'),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// True while online. Screens pause posting and show [OfflineBanner] when
/// this is false.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield service.isOnline;
  yield* service.onlineChanges;
});
