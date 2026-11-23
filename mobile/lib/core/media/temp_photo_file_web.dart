import 'dart:typed_data';

/// The web has no temporary files; the picked photo is used as it is.
Future<String?> saveTempPhoto(Uint8List bytes, String name) async => null;

Future<void> deleteTempPhoto(String path) async {}

Future<void> sweepTempPhotos({Duration age = const Duration(hours: 24)}) async {}
