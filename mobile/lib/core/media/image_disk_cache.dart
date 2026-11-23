import 'package:material_ui/material_ui.dart';

import 'image_disk_cache_io.dart'
    if (dart.library.js_interop) 'image_disk_cache_web.dart'
    as impl;

/// Downloaded server photos (posts, avatars, story thumbnails) kept on the
/// phone in `{cacheDir}/image_cache/`, so they still show offline and are
/// not downloaded again. Bounded: files unused for [maxAge] go, and the
/// oldest go once the folder passes [maxBytes]. The system may also clear
/// it when storage runs low (it is a cache folder). The web uses the
/// browser's own cache.
abstract final class ImageDiskCache {
  static const maxBytes = 100 << 20;
  static const maxAge = Duration(days: 14);

  static final instance = impl.createImageDiskCache();
}

/// See [ImageDiskCache].
abstract interface class ImageDiskCacheStore {
  /// The photo at [url], from the phone when saved, else downloaded (and
  /// saved).
  ImageProvider provider(String url);

  /// Applies the age and size limits.
  Future<void> trim();
}

/// [url] through the phone's photo cache.
ImageProvider cachedNetworkImage(String url) =>
    ImageDiskCache.instance.provider(url);
