import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> keepFile(String path, String localId) async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory(p.join(base.path, 'offline_media'));
  await dir.create(recursive: true);
  final ext = p.extension(path);
  final target = p.join(dir.path, '$localId$ext');
  await File(path).copy(target);
  return target;
}

Future<void> deleteFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
