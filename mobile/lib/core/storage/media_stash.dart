import 'media_stash_io.dart'
    if (dart.library.js_interop) 'media_stash_web.dart'
    as impl;

/// Keeps picked photos and videos for offline posts in the app's own
/// folder (`{appSupportDir}/offline_media/`), so the system cannot clear
/// them before they are uploaded.
class MediaStash {
  const MediaStash();

  /// Copies [path] into the offline folder as [localId] and returns the new
  /// path (the web keeps the picked `blob:` link as it is).
  Future<String> keep(String path, String localId) => impl.keepFile(path, localId);

  /// Deletes a kept file; a missing file is fine.
  Future<void> discard(String path) => impl.deleteFile(path);
}
