import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import 'local_file_image.dart'
    if (dart.library.js_interop) 'local_file_image_web.dart';

/// Whether [path] is a link (a server photo, or a picked photo on the web,
/// which the browser gives as a `blob:` URL) rather than a file on the
/// device.
bool isPhotoUrl(String path) =>
    path.startsWith('http://') ||
    path.startsWith('https://') ||
    path.startsWith('blob:') ||
    path.startsWith('data:');

/// A photo decoded at (roughly) the size it is shown, not at camera
/// resolution: a 12 MP picture in a 40px avatar would otherwise cost ~48 MB.
/// [path] may be a device file, a server URL, or a web `blob:` URL.
ImageProvider sizedFileImage(
  BuildContext context,
  String path, {
  required double logicalSize,
}) {
  final pixels = (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
  final ImageProvider source = kIsWeb || isPhotoUrl(path)
      ? NetworkImage(path)
      : localFileImage(path);
  return ResizeImage(source, width: pixels, policy: ResizeImagePolicy.fit);
}
