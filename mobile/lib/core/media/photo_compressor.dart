import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'temp_photo_file.dart'
    if (dart.library.js_interop) 'temp_photo_file_web.dart';
import 'upload_policy.dart';

/// Turns a picked photo into a WebP of at most [UploadPolicy.maxPhotoBytes]
/// (2 MB). It starts at 1600 px and 80% quality and steps down until the
/// photo fits, so a large photo is shrunk instead of refused. Returns null
/// only when even the smallest step is too big.
///
/// Every photo upload goes through [pickPhoto], which calls this.
class PhotoCompressor {
  const PhotoCompressor();

  /// Longest side and quality, tried in order until the photo fits.
  static const steps = <(int, int)>[
    (1600, 80),
    (1600, 70),
    (1280, 70),
    (1280, 60),
    (1024, 55),
    (800, 50),
  ];

  Future<XFile?> toWebp(XFile picked) async {
    final original = await picked.readAsBytes();
    // The web cannot write a temporary file: keep the picker's resized
    // JPEG and only check the size.
    if (kIsWeb) {
      return original.length <= UploadPolicy.maxPhotoBytes ? picked : null;
    }
    final (width, height) = await _sizeOf(original);
    for (final (side, quality) in steps) {
      // Target size keeping the shape; unknown size: fit in a square.
      final longest = width > height ? width : height;
      final scale = longest == 0 ? 0.0 : (side / longest).clamp(0.0, 1.0);
      final out = await FlutterImageCompress.compressWithList(
        original,
        minWidth: longest == 0 ? side : (width * scale).round().clamp(1, side),
        minHeight: longest == 0
            ? side
            : (height * scale).round().clamp(1, side),
        quality: quality,
        format: CompressFormat.webp,
      );
      if (out.isNotEmpty && out.length <= UploadPolicy.maxPhotoBytes) {
        final name = 'fcu_${DateTime.now().microsecondsSinceEpoch}.webp';
        final path = await saveTempPhoto(out, name);
        return path == null
            ? picked
            : XFile(path, mimeType: 'image/webp', name: name);
      }
    }
    return null;
  }

  static Future<(int, int)> _sizeOf(Uint8List bytes) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final d = await ui.ImageDescriptor.encoded(buffer);
      final size = (d.width, d.height);
      d.dispose();
      buffer.dispose();
      return size;
    } catch (_) {
      return (0, 0);
    }
  }
}

/// Tests swap this for one that does not call the platform.
final photoCompressorProvider = Provider<PhotoCompressor>(
  (ref) => const PhotoCompressor(),
);
