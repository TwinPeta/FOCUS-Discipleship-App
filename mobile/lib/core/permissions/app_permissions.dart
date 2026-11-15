import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// The runtime permissions FCU asks for.
enum AppPermission { camera, photos, notifications }

/// What the system says about one [AppPermission]. "Limited" photo access
/// and provisional notifications count as [granted]; "restricted" (parental
/// controls) counts as [permanentlyDenied], since only Settings can change it.
enum AppPermissionStatus { granted, denied, permanentlyDenied }

/// Checks and asks for runtime permissions. Screens go through
/// `ensurePermission` (permission_prompt.dart), not this directly, so the
/// reason sheet is always shown first.
abstract class PermissionService {
  Future<AppPermissionStatus> status(AppPermission permission);

  /// Shows the system dialog (when the system still allows one).
  Future<AppPermissionStatus> request(AppPermission permission);

  /// Opens this app's page in the system settings. False if it could not.
  Future<bool> openSettings();
}

/// [PermissionService] backed by `permission_handler`.
class SystemPermissionService implements PermissionService {
  const SystemPermissionService();

  // Android 12 and below read photos through READ_EXTERNAL_STORAGE
  // (storage); Android 13+ through READ_MEDIA_IMAGES (photos). The one that
  // does not apply reports a plain "denied", so the best of both wins.
  List<Permission> _handlers(AppPermission permission) => switch (permission) {
    AppPermission.camera => [Permission.camera],
    AppPermission.photos =>
      defaultTargetPlatform == TargetPlatform.android
          ? [Permission.photos, Permission.storage]
          : [Permission.photos],
    AppPermission.notifications => [Permission.notification],
  };

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async {
    final statuses = [for (final p in _handlers(permission)) await p.status];
    return _combine(statuses);
  }

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    final results = await _handlers(permission).request();
    return _combine(results.values.toList());
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  static AppPermissionStatus _combine(List<PermissionStatus> statuses) {
    final mapped = statuses.map(_map).toList();
    if (mapped.contains(AppPermissionStatus.granted)) {
      return AppPermissionStatus.granted;
    }
    if (mapped.contains(AppPermissionStatus.permanentlyDenied)) {
      return AppPermissionStatus.permanentlyDenied;
    }
    return AppPermissionStatus.denied;
  }

  static AppPermissionStatus _map(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => AppPermissionStatus.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => AppPermissionStatus.permanentlyDenied,
    PermissionStatus.denied => AppPermissionStatus.denied,
  };
}
