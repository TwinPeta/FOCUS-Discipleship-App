import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dashed_circle_painter.dart';
import '../../../../core/widgets/sized_file_image.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/theme/app_gradients.dart';

/// The Join form's 76px circular photo picker: dashed border, person icon,
/// amber "+" badge. Tapping opens a gallery/camera sheet, then [pickPhoto],
/// which asks for the camera or photos permission first.
/// Asks "gallery or camera", then picks (and resizes) a photo. Returns its
/// path, or null when cancelled.
Future<String?> choosePhoto(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;
  final picked = await pickPhoto(context, ref, source: source);
  return picked?.path;
}

class JoinPhotoPicker extends ConsumerWidget {
  const JoinPhotoPicker({
    super.key,
    required this.photoPath,
    required this.onPhotoPicked,
  });

  final String? photoPath;
  final ValueChanged<String> onPhotoPicked;

  Future<void> _showSourceSheet(BuildContext context, WidgetRef ref) async {
    final path = await choosePhoto(context, ref);
    if (path != null) onPhotoPicked(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return Column(
      children: [
        Semantics(
          button: true,
          label: hasPhoto ? 'Change profile photo' : 'Add profile photo',
          child: GestureDetector(
            onTap: () => _showSourceSheet(context, ref),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      shape: BoxShape.circle,
                      image: hasPhoto
                          ? DecorationImage(
                              image: sizedFileImage(
                                context,
                                photoPath!,
                                logicalSize: 76,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasPhoto
                        ? null
                        : CustomPaint(
                            painter: const DashedCirclePainter(),
                            child: Center(
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 32,
                                color: AppColors.placeholder,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: AppGradients.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.add, size: 16, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasPhoto ? 'Change photo' : 'Add photo',
          style: AppTextStyles.fieldLabel.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
