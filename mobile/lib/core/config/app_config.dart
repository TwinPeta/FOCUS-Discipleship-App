import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../providers/repository_providers.dart';

/// How the back office is set up, as far as the app needs to know
/// (`GET /lookups/app-config`).
class AppConfig {
  const AppConfig({required this.autoApproveJoin});

  /// Requests to join a specific community are approved at once (back
  /// office Settings > Join requests). When false, a request waits for a
  /// super-mentor and the hub shows "Pending approval" (screen 3b).
  final bool autoApproveJoin;

  static AppConfig fromJson(Object? json) {
    final j = objectOf(json) ?? const {};
    final join = objectOf(j['join_requests']) ?? const {};
    return AppConfig(autoApproveJoin: join['auto_approve'] == true);
  }
}

/// Read once per session; re-read by invalidating it.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return AppConfig.fromJson(
    await ref.watch(apiClientProvider).get('/lookups/app-config'),
  );
});

/// Whether joining is instant. False until the setting is known, so the
/// wording never promises an instant join that then waits.
final joinAutoApproveProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).valueOrNull?.autoApproveJoin ?? false,
);
