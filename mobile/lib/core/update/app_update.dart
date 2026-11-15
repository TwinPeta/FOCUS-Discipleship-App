import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// This build's number, set by CI (`--dart-define=APP_BUILD_NUMBER=<run>`).
/// 0 for local builds, which never offer updates.
const appBuildNumber = int.fromEnvironment('APP_BUILD_NUMBER');

/// Where Android test builds are published (`.github/workflows/mobile-apk.yml`).
const _latestReleaseUrl =
    'https://api.github.com/repos/TwinPeta/FOCUS-Discipleship-App/releases/latest';

/// A newer Android build on GitHub Releases.
class AppUpdate {
  const AppUpdate({required this.buildNumber, required this.downloadUrl});

  final int buildNumber;

  /// Direct link to `fcu.apk`; opened in the browser to download and install.
  final String downloadUrl;
}

/// Reads a GitHub "latest release" response: tag `android-build-<n>` with an
/// `.apk` asset. Returns null when it is not newer than [current].
AppUpdate? parseLatestRelease(
  Map<String, dynamic> json, {
  required int current,
}) {
  final tag = json['tag_name'];
  final match = tag is String
      ? RegExp(r'^android-build-(\d+)$').firstMatch(tag)
      : null;
  if (match == null) return null;
  final build = int.parse(match.group(1)!);
  if (build <= current) return null;
  final assets = json['assets'];
  if (assets is! List) return null;
  for (final a in assets.whereType<Map<String, dynamic>>()) {
    final name = a['name'];
    final url = a['browser_download_url'];
    if (name is String && name.endsWith('.apk') && url is String) {
      return AppUpdate(buildNumber: build, downloadUrl: url);
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

/// The current build number; overridable in tests.
final currentBuildNumberProvider = Provider<int>((ref) => appBuildNumber);

/// A newer Android build, or null (not Android, a local build, offline, or
/// already up to date). Checked once per app start; failures are silent.
final appUpdateProvider = FutureProvider<AppUpdate?>((ref) async {
  final current = ref.watch(currentBuildNumberProvider);
  final onAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (current <= 0 || !onAndroid) return null;
  try {
    final json = await ref.watch(latestReleaseFetcherProvider)();
    return json == null ? null : parseLatestRelease(json, current: current);
  } catch (_) {
    return null;
  }
});
