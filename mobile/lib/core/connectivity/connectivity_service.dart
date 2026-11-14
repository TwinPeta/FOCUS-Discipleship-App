import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Online/offline status. Only a fake exists for now; a real implementation
/// (e.g. `connectivity_plus`) can replace [FakeConnectivityService] later
/// without touching any screen.
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onlineChanges;

  /// Re-checks the connection (the banner's Retry). Returns the new state.
  Future<bool> check();
}

class FakeConnectivityService implements ConnectivityService {
  // ignore: prefer_initializing_formals
  FakeConnectivityService({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  @override
  Future<bool> check() async => _online;

  /// Debug scenarios and tests flip the connection here.
  void setOnline(bool online) {
    if (online == _online) return;
    _online = online;
    _controller.add(online);
  }

  void dispose() => _controller.close();
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = FakeConnectivityService();
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
