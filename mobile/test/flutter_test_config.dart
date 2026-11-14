import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tests use the bundled Source Sans 3 (assets/google_fonts/) exactly like
/// the app: no runtime fetching. Every weight is loaded once up front so no
/// font finishes loading mid-test (which would schedule a stray frame) and
/// goldens render real glyphs. Material Icons are loaded from the Flutter
/// SDK so icons in goldens are not drawn as boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUpAll(() async {
    for (final weight in [400, 500, 600, 700, 800, 900]) {
      GoogleFonts.sourceSans3(fontWeight: FontWeight.values[weight ~/ 100 - 1]);
    }
    await GoogleFonts.pendingFonts();
    await _loadMaterialIcons();
  });
  await testMain();
}

Future<void> _loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}
