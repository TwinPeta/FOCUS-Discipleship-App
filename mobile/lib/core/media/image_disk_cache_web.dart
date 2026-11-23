import 'package:material_ui/material_ui.dart';

import 'image_disk_cache.dart';

ImageDiskCacheStore createImageDiskCache() => _BrowserCache();

class _BrowserCache implements ImageDiskCacheStore {
  @override
  ImageProvider provider(String url) => NetworkImage(url);

  @override
  Future<void> trim() async {}
}
