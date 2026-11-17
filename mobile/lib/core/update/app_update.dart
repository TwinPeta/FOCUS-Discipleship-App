import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_info.dart';

/// Where Android releases are published (`.github/workflows/mobile-apk.yml`).
/// Each release is one app version: tag `mobile-v<version>`, asset `fcu.apk`.
const _latestReleaseUrl =
    'https://api.github.com/repos/TwinPeta/FOCUS-Discipleship-App/releases/latest';

/// The release tag for [version] (`mobile-v1.0.0-beta.2`).
const releaseTagPrefix = 'mobile-v';

/// The APK the app installs from a release. Other APKs on the same release
/// (for example a differently signed one) are never offered.
const releaseApkName = 'fcu.apk';

/// A newer Android version on GitHub Releases.
class AppUpdate {
  const AppUpdate({required this.version, required this.downloadUrl});

  /// e.g. `1.0.0-beta.2`.
  final String version;

  /// Direct link to `fcu.apk`; opened in the browser to download and install.
  final String downloadUrl;
}

final _semver = RegExp(
  r'^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
);

/// Compares two versions the way semantic versioning does: 1.0.0-beta.2 is
/// newer than 1.0.0-beta.1 and older than 1.0.0; build metadata (`+5`) is
/// ignored. Negative when [a] is older, positive when newer, 0 when equal.
/// Null when either is not a version.
int? compareVersions(String a, String b) {
  final x = _semver.firstMatch(a.trim());
  final y = _semver.firstMatch(b.trim());
  if (x == null || y == null) return null;
  for (var i = 1; i <= 3; i++) {
    final d = int.parse(x.group(i)!).compareTo(int.parse(y.group(i)!));
    if (d != 0) return d;
  }
  final px = x.group(4);
  final py = y.group(4);
  if (px == null || py == null) {
    // A release (no "-beta") is newer than any of its pre-releases.
    return px == py ? 0 : (px == null ? 1 : -1);
  }
  final ix = px.split('.');
  final iy = py.split('.');
  for (var i = 0; i < ix.length && i < iy.length; i++) {
    final nx = int.tryParse(ix[i]);
    final ny = int.tryParse(iy[i]);
    final d = (nx != null && ny != null)
        ? nx.compareTo(ny)
        // Numbers sort before words; words sort alphabetically.
        : (nx != null)
        ? -1
        : (ny != null)
        ? 1
        : ix[i].compareTo(iy[i]);
    if (d != 0) return d;
  }
  return ix.length.compareTo(iy.length);
}

/// Reads a GitHub "latest release" response: tag `mobile-v<version>` with an
/// `fcu.apk` asset. Returns null when it is not newer than [current].
AppUpdate? parseLatestRelease(
  Map<String, dynamic> json, {
  required String current,
}) {
  final tag = json['tag_name'];
  if (tag is! String || !tag.startsWith(releaseTagPrefix)) return null;
  final version = tag.substring(releaseTagPrefix.length);
  final newer = compareVersions(version, current);
  if (newer == null || newer <= 0) return null;
  final assets = json['assets'];
  if (assets is! List) return null;
  for (final a in assets.whereType<Map<String, dynamic>>()) {
    final url = a['browser_download_url'];
    if (a['name'] == releaseApkName && url is String) {
      return AppUpdate(version: version, downloadUrl: url);
    }
  }
  return null;
}

/// Injectable for tests: fetches the latest-release JSON.
final latestReleaseFetcherProvider =
    Provider<Future<Map<String, dynamic>?> Function()>((ref) {
      return () async {
        final response = await http
            .get(
              Uri.parse(_latestReleaseUrl),
              headers: {'Accept': 'application/vnd.github+json'},
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return null;
        final body = jsonDecode(response.body);
        return body is Map<String, dynamic> ? body : null;
      };
    });

/// This build's version (empty for local builds); overridable in tests.
final currentVersionProvider = Provider<String>((ref) => appVersion);

/// A newer Android version, or null (not Android, a local build, offline, or
/// already up to date). Checked once per app start; failures are silent.
final appUpdateProvider = FutureProvider<AppUpdate?>((ref) async {
  final current = ref.watch(currentVersionProvider);
  final onAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (current.isEmpty || !onAndroid) return null;
  try {
    final json = await ref.watch(latestReleaseFetcherProvider)();
    return json == null ? null : parseLatestRelease(json, current: current);
  } catch (_) {
    return null;
  }
});
