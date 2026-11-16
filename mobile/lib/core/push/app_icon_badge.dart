import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

int? _shown;

/// Puts [count] on the app's home-screen icon (0 clears it). Android
/// launchers that support badges and iOS show it; elsewhere, and on the web
/// or in tests, nothing happens. Never throws.
Future<void> updateAppIconBadge(int count) async {
  if (kIsWeb || count == _shown) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  _shown = count;
  try {
    if (await AppBadgePlus.isSupported()) {
      await AppBadgePlus.updateBadge(count);
    }
  } catch (_) {
    // A launcher without badge support: the in-app counts still show.
  }
}
