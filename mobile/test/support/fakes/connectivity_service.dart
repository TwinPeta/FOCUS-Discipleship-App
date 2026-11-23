import 'dart:async';

import 'package:focus_1/core/connectivity/connectivity_service.dart';

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

  @override
  void reportUnreachable() => setOnline(false);

  @override
  void reportReachable() => setOnline(true);

  void dispose() => _controller.close();
}
