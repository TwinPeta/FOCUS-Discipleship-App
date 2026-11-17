import 'package:material_ui/material_ui.dart';

/// The web has no device files: a picked photo is a browser link.
ImageProvider localFileImage(String path) => NetworkImage(path);
