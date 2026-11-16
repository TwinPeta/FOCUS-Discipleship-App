/// What members can upload, in one place (storage is a small S3 bucket):
/// text, emojis, photos, and one short video on a story. No documents.
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

  /// Story videos: at most 2 minutes (the server checks it too) and 100 MB.
  static const maxVideoDuration = Duration(minutes: 2);
  static const maxVideoBytes = 100 * 1024 * 1024;

  /// Null when the video is acceptable, otherwise the message to show.
  /// [length] is null when it could not be measured.
  static String? checkVideo({required int bytes, required Duration? length}) {
    if (length == null) {
      return 'We could not read that video. Please choose another one.';
    }
    if (length > maxVideoDuration) {
      final s = length.inSeconds;
      return 'Videos can be at most 2 minutes. This one is '
          '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}.';
    }
    if (bytes > maxVideoBytes) {
      return 'That video is too large. Please choose one under 100 MB.';
    }
    return null;
  }

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
