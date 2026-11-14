import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/error_snack.dart';
import 'upload_policy.dart';

/// Picks one photo, compressed to [UploadPolicy.photoQuality] and resized to
/// [UploadPolicy.photoMaxDimension], then checked against [UploadPolicy]
/// (format and 2 MB). Returns null when cancelled or refused; a refusal
/// shows the reason. Every photo upload in the app goes through here.
Future<XFile?> pickPhoto(
  BuildContext context, {
  ImageSource source = ImageSource.gallery,
  ImagePicker? picker,
}) async {
  final picked = await (picker ?? ImagePicker()).pickImage(
    source: source,
    maxWidth: UploadPolicy.photoMaxDimension,
    maxHeight: UploadPolicy.photoMaxDimension,
    imageQuality: UploadPolicy.photoQuality,
  );
  if (picked == null) return null;
  final problem = UploadPolicy.checkPhoto(
    name: picked.name,
    bytes: await picked.length(),
  );
  if (problem != null) {
    if (context.mounted) showErrorSnack(context, problem);
    return null;
  }
  return picked;
}
