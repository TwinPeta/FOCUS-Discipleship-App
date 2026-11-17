import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// A photo stored on the device (Android, iOS, desktop).
ImageProvider localFileImage(String path) => FileImage(File(path));
