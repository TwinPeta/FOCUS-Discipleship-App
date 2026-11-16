import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../permissions/app_permissions.dart';
import '../permissions/permission_prompt.dart';
import '../widgets/error_snack.dart';
import 'photo_compressor.dart';
import 'upload_policy.dart';

/// Picks one photo (resized to [UploadPolicy.photoMaxDimension]), checks its
/// format, then converts it to WebP under 2 MB with [PhotoCompressor].
/// Returns null when cancelled or refused; a refusal shows the reason.
/// Every photo upload in the app goes through here.
///
/// First asks for the camera or photos permission (with a reason sheet, see
/// [ensurePermission]); the web has no runtime permissions, so it skips that.
Future<XFile?> pickPhoto(
  BuildContext context,
  WidgetRef ref, {
  ImageSource source = ImageSource.gallery,
  ImagePicker? picker,
}) async {
  if (!kIsWeb) {
    final camera = source == ImageSource.camera;
    final allowed = await ensurePermission(
      context,
      ref,
      camera ? AppPermission.camera : AppPermission.photos,
      camera ? PermissionReasons.cameraPhoto : PermissionReasons.photosPick,
    );
    if (!allowed) return null;
  }
  final picked = await (picker ?? ImagePicker()).pickImage(
    source: source,
    maxWidth: UploadPolicy.photoMaxDimension,
    maxHeight: UploadPolicy.photoMaxDimension,
    imageQuality: UploadPolicy.photoQuality,
  );
  if (picked == null) return null;
  final format = UploadPolicy.checkPhotoFormat(picked.name);
  if (format != null) {
    if (context.mounted) showErrorSnack(context, format);
    return null;
  }
  // WebP, at most 2 MB: big photos are shrunk, not refused.
  final compressed = await ref.read(photoCompressorProvider).toWebp(picked);
  if (compressed == null) {
    if (context.mounted) {
      showErrorSnack(
        context,
        'That photo is too large even after compressing. '
        'Please choose another one.',
      );
    }
    return null;
  }
  return compressed;
}
