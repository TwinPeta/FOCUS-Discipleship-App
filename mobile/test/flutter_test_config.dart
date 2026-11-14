import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Widget tests run without network access. `google_fonts` otherwise tries
/// to fetch font files over HTTP on first use, which hangs/times out here
/// and makes every test using [AppTextStyles] extremely slow. Fall back to
/// the bundled system font instead.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
