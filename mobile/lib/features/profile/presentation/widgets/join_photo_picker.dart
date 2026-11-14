import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dashed_circle_painter.dart';
import '../../../../core/widgets/sized_file_image.dart';
import '../../../../core/media/photo_picker.dart';

/// The Join form's 76px circular photo picker: dashed border, person icon,
/// amber "+" badge. Tapping opens a gallery/camera sheet via image_picker.
class JoinPhotoPicker extends StatelessWidget {
  const JoinPhotoPicker({
    super.key,
    required this.photoPath,
    required this.onPhotoPicked,
  });

  final String? photoPath;
  final ValueChanged<String> onPhotoPicked;

  Future<void> _showSourceSheet(BuildContext context) async {
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
    if (source == null) return;
    if (!context.mounted) return;
    final picked = await pickPhoto(context, source: source);
    if (picked != null) {
      onPhotoPicked(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return Column(
      children: [
        Semantics(
          button: true,
          label: hasPhoto ? 'Change profile photo' : 'Add profile photo',
          child: GestureDetector(
            onTap: () => _showSourceSheet(context),
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
                        : const CustomPaint(
                            painter: DashedCirclePainter(),
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
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add photo',
          style: AppTextStyles.fieldLabel.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
