import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/update/app_update.dart';
import '../../../core/utils/open_link.dart';
import 'settings_screen.dart';

/// "App updates" on Settings (46). On an Android release build, tapping it
/// asks GitHub for the latest version: a newer one opens its APK in the
/// browser (Android then offers to install it over this app); otherwise it
/// says the app is up to date, or that the check could not reach GitHub.
/// Development builds and iPhones cannot update themselves, so the row
/// only explains that.
class AppUpdateRow extends ConsumerStatefulWidget {
  const AppUpdateRow({super.key});

  @override
  ConsumerState<AppUpdateRow> createState() => _AppUpdateRowState();
}

class _AppUpdateRowState extends ConsumerState<AppUpdateRow> {
  var _checking = false;

  /// Set once a check from this row finishes: true when up to date.
  bool? _upToDate;

  Future<void> _check() async {
    if (_checking) return;
    // An update the start-up check already found: download it directly.
    final known = ref.read(appUpdateProvider).valueOrNull;
    if (known != null) return openExternalLink(context, known.downloadUrl);

    setState(() => _checking = true);
    AppUpdate? found;
    var failed = false;
    try {
      found = await ref.read(updateCheckProvider)();
    } on UpdateCheckFailed {
      failed = true;
    }
    if (!mounted) return;
    final message = failed
        ? 'Could not check for updates. Check your internet and try again.'
        : found == null
        ? 'You have the latest version.'
        : 'Version ${found.version} is ready. Downloading…';
    setState(() {
      _checking = false;
      _upToDate = failed ? null : found == null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (found != null) {
      // The Home banner shows it too from now on.
      ref.invalidate(appUpdateProvider);
      await openExternalLink(context, found.downloadUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentVersionProvider);
    final known = ref.watch(appUpdateProvider).valueOrNull;
    final canUpdate = canSelfUpdate(current);
    final subtitle = !canUpdate
        ? (current.isEmpty
              ? 'Development build: no updates'
              : 'Install new versions from the testers’ page')
        : _checking
        ? 'Checking…'
        : known != null
        ? 'Version ${known.version} is ready · Tap to update'
        : _upToDate == true
        ? 'Up to date · Version $current'
        : 'Version $current · Tap to check';
    return Semantics(
      liveRegion: true,
      child: SettingsRow(
        icon: known != null
            ? Icons.system_update_rounded
            : Icons.update_rounded,
        title: 'App updates',
        subtitle: subtitle,
        onTap: canUpdate && !_checking ? () => unawaited(_check()) : null,
      ),
    );
  }
}
