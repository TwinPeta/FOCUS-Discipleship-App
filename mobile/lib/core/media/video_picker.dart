import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../permissions/app_permissions.dart';
import '../permissions/permission_prompt.dart';
import '../widgets/error_snack.dart';
import 'upload_policy.dart';

/// A picked video and its length.
class PickedVideo {
  const PickedVideo({required this.path, required this.duration});

  final String path;
  final Duration duration;

  /// "1:45".
  String get lengthLabel {
    final s = duration.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

/// Measures a video's length (null when it cannot be read).
typedef VideoLengthReader = Future<Duration?> Function(String path);

Future<Duration?> _readLength(String path) async {
  final controller = kIsWeb || path.startsWith('blob:')
      ? VideoPlayerController.networkUrl(Uri.parse(path))
      : VideoPlayerController.networkUrl(Uri.file(path));
  try {
    await controller.initialize().timeout(const Duration(seconds: 15));
    return controller.value.duration;
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}

/// Picks one story video of at most [UploadPolicy.maxVideoDuration]
/// (2 minutes) and [UploadPolicy.maxVideoBytes]. Recording with the camera
/// stops at the limit; a longer video from the gallery is refused with its
/// length. Returns null when cancelled or refused (a refusal shows why).
Future<PickedVideo?> pickVideo(
  BuildContext context,
  WidgetRef ref, {
  ImageSource source = ImageSource.gallery,
  ImagePicker? picker,
  VideoLengthReader? readLength,
}) async {
  if (!kIsWeb) {
    final camera = source == ImageSource.camera;
    final allowed = await ensurePermission(
      context,
      ref,
      camera ? AppPermission.camera : AppPermission.photos,
      camera ? PermissionReasons.cameraVideo : PermissionReasons.videoPick,
    );
    if (!allowed) return null;
  }
  final picked = await (picker ?? ImagePicker()).pickVideo(
    source: source,
    maxDuration: UploadPolicy.maxVideoDuration,
  );
  if (picked == null) return null;

  final bytes = await picked.length();
  final length = await (readLength ?? _readLength)(picked.path);
  final problem = UploadPolicy.checkVideo(bytes: bytes, length: length);
  if (problem != null) {
    if (context.mounted) showErrorSnack(context, problem);
    return null;
  }
  return PickedVideo(path: picked.path, duration: length!);
}
