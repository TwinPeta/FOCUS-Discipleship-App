import 'package:focus_1/core/media/photo_compressor.dart';
import 'package:focus_1/core/media/upload_policy.dart';
import 'package:image_picker/image_picker.dart' show XFile;

/// Demo and tests: no platform encoder. Keeps the photo as picked and
/// applies the same 2 MB limit, so a photo it cannot shrink is refused.
class FakePhotoCompressor extends PhotoCompressor {
  const FakePhotoCompressor();

  @override
  Future<XFile?> toWebp(XFile picked) async =>
      await picked.length() <= UploadPolicy.maxPhotoBytes ? picked : null;
}
