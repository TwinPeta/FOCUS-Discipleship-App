import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/post_photo_art.dart';
import '../../../../core/widgets/sized_file_image.dart';
import '../../domain/post.dart';

/// The widget for a post's photo (seeded art, a picked file or an uploaded photo), or null
/// when the post has none. Shared by the feed and the post screen.
Widget? postPhotoView(BuildContext context, PostPhoto? photo) {
  return switch (photo) {
    null => null,
    PostPhoto(isArt: true) => const PostPhotoArt(),
    PostPhoto(:final path?) => Image(
      image: sizedFileImage(
        context,
        path,
        logicalSize: MediaQuery.sizeOf(context).width,
      ),
      fit: BoxFit.cover,
    ),
    // Decoded at the width it is shown (not camera resolution), and kept
    // on the phone so it shows offline.
    PostPhoto(:final url?) => Image(
      image: sizedFileImage(
        context,
        url,
        logicalSize: MediaQuery.sizeOf(context).width,
      ),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
    PostPhoto() => null,
  };
}
