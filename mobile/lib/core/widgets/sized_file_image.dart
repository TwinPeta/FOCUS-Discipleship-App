import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// A local photo decoded at (roughly) the size it is shown, not at camera
/// resolution: a 12 MP picture in a 40px avatar would otherwise cost ~48 MB.
ImageProvider sizedFileImage(
  BuildContext context,
  String path, {
  required double logicalSize,
}) {
  final pixels = (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
  return ResizeImage(
    FileImage(File(path)),
    width: pixels,
    policy: ResizeImagePolicy.fit,
  );
}
