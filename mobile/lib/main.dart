import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/push/push_service.dart';
import 'core/realtime/realtime_bindings.dart';
import 'core/push/firebase_push.dart';
import 'core/router/app_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/palette_sync.dart';
import 'core/theme/theme_mode_provider.dart';
import 'demo/demo_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureFonts();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Phone notifications (local only); a no-op on web. Tests never run main.
  await LocalPushPlatform.instance.init();
  // Remote push (only when this build has its Firebase identifiers; otherwise a no-op).
  await FirebasePush.init();
  // Web demo build (DEMO_MODE): sample data, already in a community.
  final overrides = kDemoMode ? await demoOverrides() : <Override>[];
  // Saved settings (theme). The app still runs if storage is unavailable.
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}
  runApp(
    ProviderScope(
      overrides: [
        ...overrides,
        sharedPreferencesProvider.overrideWithValue(prefs),
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
          child: kDemoMode
              ? Banner(
                  message: 'DEMO',
                  location: BannerLocation.topEnd,
                  color: const Color(0xFF17140C),
                  child: child!,
                )
              : child!,
        ),
      ),
    );
  }
}
