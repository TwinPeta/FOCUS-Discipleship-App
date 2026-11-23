import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/media/image_disk_cache.dart';
import 'core/media/photo_compressor.dart';
import 'core/network/api_client.dart';
import 'core/network/token_vault.dart';
import 'core/providers/repository_providers.dart';
import 'core/push/push_service.dart';
import 'core/realtime/realtime_bindings.dart';
import 'core/push/firebase_push.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_database.dart';
import 'core/storage/sqflite_local_database.dart';
import 'core/sync/sync_engine.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/palette_sync.dart';
import 'core/theme/theme_mode_provider.dart';

/// Marks that no sign-in is saved, so the next launch can skip the
/// Keystore / Keychain (slow on its first use). Absent on a fresh install
/// and on phones updated from older versions: the vault is then read once.
const _hasSessionKey = 'fcu.has_session';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureFonts();
  // Decoded photos kept in memory: Flutter's default (100 MB, 1000 images)
  // gets the app killed in the background on 2-3 GB phones, for example
  // while the camera is open. Flutter also empties it on memory pressure.
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 50 << 20;

  // Everything below is independent, so it runs at the same time instead
  // of one step after another before the first frame.
  final tokens = TokenStore(vault: SecureTokenVault());
  SharedPreferences? prefs;
  LocalDatabase db = MemoryLocalDatabase();
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    // Phone notifications (local only); a no-op on web. Tests never run main.
    LocalPushPlatform.instance.init(),
    // Remote push (only when this build has its Firebase identifiers;
    // otherwise a no-op).
    FirebasePush.init(),
    () async {
      // Saved settings (theme). The app still runs without them.
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (_) {}
      // The saved sign-in (Keychain / encrypted storage): a student signs
      // in once and stays signed in until they log out.
      await tokens.restore(knownEmpty: prefs?.getBool(_hasSessionKey) == false);
      final saved = prefs;
      if (saved != null) {
        unawaited(saved.setBool(_hasSessionKey, tokens.hasSession));
        tokens.onSavedChanged = (has) =>
            unawaited(saved.setBool(_hasSessionKey, has));
      }
    }(),
    () async {
      // Saved content and offline writes (SQLite). In memory on the web, or
      // if the database cannot be opened: the app still runs, not offline.
      if (kIsWeb) return;
      try {
        db = await SqfliteLocalDatabase.open();
      } catch (_) {}
    }(),
  ]);
  // Housekeeping after the first frame: old downloaded photos and leftover
  // temporary photo files.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(ImageDiskCache.instance.trim());
    unawaited(sweepStaleTempPhotos());
  });
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
        localDatabaseProvider.overrideWithValue(db),
      ],
      child: const FcuApp(),
    ),
  );
}

/// Bricolage Grotesque ships in `assets/fonts/` (declared in pubspec.yaml),
/// so nothing is fetched at runtime. Registers its OFL licence.
void configureFonts() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Bricolage Grotesque'], license);
  });
}

class FcuApp extends ConsumerWidget {
  const FcuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Live updates (realtime socket) and device registration; no-ops when
    // the API is off.
    ref.watch(realtimeBindingsProvider);
    // Sends writes made offline once the server can be reached.
    ref.watch(syncEngineProvider);
    return MaterialApp.router(
      title: 'FCU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      // Light: every screen sits on amber, cream or white, so dark
      // status-bar icons. Dark theme: light icons.
      builder: (context, child) => PaletteSync(
        dark: Theme.of(context).brightness == Brightness.dark,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              (Theme.of(context).brightness == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(statusBarColor: const Color(0x00000000)),
          child: child!,
        ),
      ),
    );
  }
}
