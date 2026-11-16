import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;

import 'api_client.dart';

/// Uploads a picked photo: asks the API for an upload slot, sends the bytes
/// (straight to the storage bucket, or to the API when no bucket is set up),
/// and returns the `media_id` to attach to a post, testimony or profile.
class MediaUploader {
  MediaUploader(this._api, {http.Client? client})
    : _http = client ?? http.Client();

  final ApiClient _api;
  final http.Client _http;

  static String contentTypeOf(String path) {
    final dot = path.lastIndexOf('.');
    switch (dot == -1 ? '' : path.substring(dot + 1).toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic' || 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// [purpose]: `post_photo`, `testimony_photo`, `profile_photo` or
  /// `report_evidence`. Throws [ApiException] on any failure.
  Future<String> uploadPhoto(String path, {required String purpose}) async {
    // XFile reads a device file and, on the web, the picked photo's
    // `blob:` link alike.
    final bytes = await XFile(path).readAsBytes();
    final type = contentTypeOf(path);
    final slot = objectOf(
      await _api.post(
        '/media',
        body: {
          'purpose': purpose,
          'content_type': type,
          'size_bytes': bytes.length,
        },
      ),
    );
    final id = slot?['media_id'] as String?;
    final url = slot?['upload_url'] as String?;
    if (id == null || url == null) {
      throw const ApiException(500, message: 'No upload slot');
    }

    final request = http.Request('PUT', Uri.parse(url))
      ..bodyBytes = bytes
      ..headers['Content-Type'] = type;
    // Uploads to the API itself need the login token; signed bucket URLs
    // must not carry it.
    if (url.startsWith(_api.baseUrl.replaceFirst(RegExp(r'/v1$'), ''))) {
      final token = _api.tokens.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }
    try {
      final response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(minutes: 2)),
      );
      if (response.statusCode >= 300) {
        throw ApiException(response.statusCode, message: 'Upload failed');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(0, message: 'Could not upload the photo');
    }
    await _api.post('/media/$id/complete');
    return id;
  }
}
