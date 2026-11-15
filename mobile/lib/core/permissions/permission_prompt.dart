import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/repository_providers.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/bottom_sheet_scaffold.dart';
import 'app_permissions.dart';

/// Ready-made reasons for the sheet ensurePermission shows first.
abstract final class PermissionReasons {
  static const cameraPhoto =
      'FCU needs your camera to take a photo for your post, profile or '
      'report.';
  static const photosPick =
      'FCU needs access to your photos so you can choose one for your post, '
      'profile or report.';
  static const notifications =
      'FCU needs to send you notifications about messages, prayer requests '
      'and meetings.';
}

/// Minimum button height on the permission sheets (44px touch target).
const double _buttonHeight = 48;

/// Makes sure [permission] is granted before a feature uses it.
///
/// Already granted: returns true straight away. Otherwise shows a short sheet
/// with [reason] (Continue / Not now) and, on Continue, the system request.
/// If the system will no longer ask (permanently denied), explains how to
/// turn it on and offers "Open settings". Returns true only when granted.
Future<bool> ensurePermission(
  BuildContext context,
  WidgetRef ref,
  AppPermission permission,
  String reason,
) async {
  final service = ref.read(permissionServiceProvider);
  var status = await service.status(permission);
  if (status == AppPermissionStatus.granted) return true;

  if (status == AppPermissionStatus.denied) {
    if (!context.mounted) return false;
    final proceed = await showAppBottomSheet<bool>(
      context,
      builder: (_) => _PermissionSheet(
        title: _askTitle(permission),
        message: reason,
        actionLabel: 'Continue',
      ),
    );
    if (proceed != true) return false;
    status = await service.request(permission);
    if (status == AppPermissionStatus.granted) return true;
  }

  if (status == AppPermissionStatus.permanentlyDenied && context.mounted) {
    final openSettings = await showAppBottomSheet<bool>(
      context,
      builder: (_) => _PermissionSheet(
        title: '${_name(permission)} access is off',
        message:
            '$reason To turn it on, open Settings, then allow '
            '${_name(permission)} for FCU.',
        actionLabel: 'Open settings',
      ),
    );
    if (openSettings == true) await service.openSettings();
  }
  return false;
}

String _name(AppPermission permission) => switch (permission) {
  AppPermission.camera => 'Camera',
  AppPermission.photos => 'Photos',
  AppPermission.notifications => 'Notifications',
};

String _askTitle(AppPermission permission) => switch (permission) {
  AppPermission.camera => 'Allow camera',
  AppPermission.photos => 'Allow photos',
  AppPermission.notifications => 'Allow notifications',
};

/// Reason + main action + "Not now". Pops true for the main action.
class _PermissionSheet extends StatelessWidget {
  const _PermissionSheet({
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      title: title,
      children: [
        Text(message, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: actionLabel,
          height: _buttonHeight,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: 'Not now',
          height: _buttonHeight,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
