import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/post_photo_art.dart';
import '../../../../core/widgets/sized_file_image.dart';
import '../../domain/post.dart';

/// The widget for a post's photo (seeded art or a picked file), or null
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
    PostPhoto() => null,
  };
}
