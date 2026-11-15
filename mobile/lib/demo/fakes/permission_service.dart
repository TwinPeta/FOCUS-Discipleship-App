import 'package:focus_1/core/permissions/app_permissions.dart';

/// Scripted permissions. Every permission starts at [initial]; a request
/// moves it to [onRequest] (granted by default).
class FakePermissionService implements PermissionService {
  FakePermissionService({
    AppPermissionStatus initial = AppPermissionStatus.granted,
    this.onRequest = AppPermissionStatus.granted,
  }) : _statuses = {for (final p in AppPermission.values) p: initial};

  final Map<AppPermission, AppPermissionStatus> _statuses;
  final AppPermissionStatus onRequest;

  final List<AppPermission> requested = [];
  int settingsOpened = 0;

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async =>
      _statuses[permission]!;

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    requested.add(permission);
    return _statuses[permission] = onRequest;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}
