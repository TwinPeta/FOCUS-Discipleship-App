import 'dart:io';
import 'dart:typed_data';

/// Saves compressed photo bytes to a temporary file and returns its path
/// (Android, iOS, desktop). The upload reads it back from there.
Future<String?> saveTempPhoto(Uint8List bytes, String name) async {
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
