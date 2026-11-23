import 'dart:io';
import 'dart:typed_data';

/// Saves compressed photo bytes to a temporary file and returns its path
/// (Android, iOS, desktop). The upload reads it back from there.
Future<String?> saveTempPhoto(Uint8List bytes, String name) async {
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// Deletes a temporary photo file; a missing file is fine.
Future<void> deleteTempPhoto(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}

/// Removes leftover temporary photos older than [age]: the app's compressed
/// copies (`fcu_*.webp`) and the photo picker's own copies, which nothing
/// else deletes. Photos for writes made offline live in `offline_media/`,
/// which this does not touch.
Future<void> sweepTempPhotos({Duration age = const Duration(hours: 24)}) async {
  try {
    final dir = Directory.systemTemp;
    final cutoff = DateTime.now().subtract(age);
    await for (final entry in dir.list()) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      final ours =
          (name.startsWith('fcu_') && name.endsWith('.webp')) ||
          name.startsWith('image_picker');
      if (!ours) continue;
      if ((await entry.stat()).modified.isBefore(cutoff)) {
        await entry.delete();
      }
    }
  } catch (_) {}
}
