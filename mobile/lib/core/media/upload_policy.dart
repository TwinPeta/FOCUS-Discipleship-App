/// What members can upload, in one place (storage is a small S3 bucket).
/// For now: text, emojis and photos. No videos or documents.
class UploadPolicy {
  UploadPolicy._();

  /// Common photo formats. Others (GIF, video, documents) are refused.
  static const photoExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

  /// Hard limit per photo after compression.
  static const maxPhotoBytes = 2 * 1024 * 1024;

  /// JPEG quality used when picking (80%).
  static const photoQuality = 80;

  /// Longest side after resizing, which keeps most photos far under 2 MB.
  static const photoMaxDimension = 1600.0;

  /// Text limits (emojis included).
  static const maxPostChars = 2000;
  static const maxMessageChars = 1000;

  static String extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  /// Null when the photo is acceptable, otherwise the message to show.
  static String? checkPhoto({required String name, required int bytes}) {
    if (!photoExtensions.contains(extensionOf(name))) {
      return 'Please choose a photo (JPG, PNG, WebP or HEIC).';
    }
    if (bytes > maxPhotoBytes) {
      return 'That photo is too large. Please choose one under 2 MB.';
    }
    return null;
  }
}
