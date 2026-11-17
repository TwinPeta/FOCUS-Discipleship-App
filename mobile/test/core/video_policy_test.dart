import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/core/media/upload_policy.dart';
import 'package:focus_1/core/media/video_picker.dart';
import 'package:focus_1/core/network/media_uploader.dart';

void main() {
  group('story videos', () {
    test('up to 2 minutes is accepted', () {
      expect(
        UploadPolicy.checkVideo(
          bytes: 20 * 1024 * 1024,
          length: const Duration(minutes: 1, seconds: 59),
        ),
        isNull,
      );
      expect(
        UploadPolicy.checkVideo(
          bytes: 1000,
          length: const Duration(minutes: 2),
        ),
        isNull,
      );
    });

    test('longer than 2 minutes is refused, with its length', () {
      expect(
        UploadPolicy.checkVideo(
          bytes: 1000,
          length: const Duration(minutes: 3, seconds: 12),
        ),
        'Videos can be at most 2 minutes. This one is 3:12.',
      );
    });

    test('too large or unreadable is refused', () {
      expect(
        UploadPolicy.checkVideo(
          bytes: 200 * 1024 * 1024,
          length: const Duration(seconds: 30),
        ),
        contains('too large'),
      );
      expect(
        UploadPolicy.checkVideo(bytes: 1000, length: null),
        contains('could not read'),
      );
    });

    test('labels and upload types', () {
      expect(
        const PickedVideo(
          path: 'a.mp4',
          duration: Duration(seconds: 105),
        ).lengthLabel,
        '1:45',
      );
      expect(MediaUploader.videoTypeOf('clip.mov'), 'video/quicktime');
      expect(MediaUploader.videoTypeOf('clip.webm'), 'video/webm');
      expect(MediaUploader.videoTypeOf('clip.mp4'), 'video/mp4');
    });
  });
}
