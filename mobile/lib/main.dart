import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureFonts();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: FcuApp()));
}

/// Source Sans 3 ships in `assets/google_fonts/`; never fetch it at runtime.
void configureFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
}

class FcuApp extends ConsumerWidget {
  const FcuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FCU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      // Every screen sits on amber, cream or white: dark status-bar icons.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: const Color(0x00000000),
        ),
        child: child!,
      ),
    );
  }
}
