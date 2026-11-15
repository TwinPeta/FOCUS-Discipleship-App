import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests use the bundled Bricolage Grotesque (assets/fonts/) exactly like
/// the app. flutter_test does not load pubspec fonts by itself, so every
/// weight is loaded once up front: goldens render real glyphs and no font
/// finishes loading mid-test. Material Icons are loaded from the Flutter
/// SDK so icons in goldens are not drawn as boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _loadBricolage();
    await _loadMaterialIcons();
  });
  await testMain();
}

Future<void> _loadBricolage() async {
  final loader = FontLoader('BricolageGrotesque');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final file = File('assets/fonts/BricolageGrotesque-$weight.ttf');
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
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
