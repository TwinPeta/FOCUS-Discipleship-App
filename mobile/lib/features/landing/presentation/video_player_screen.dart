import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/open_link.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/empty_state.dart';

/// In-app YouTube player (`/watch?url=&title=`), public like the landing
/// page. Non-YouTube links never reach here (`openVideo` opens them
/// outside the app).
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.url, this.title});

  final String url;
  final String? title;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final id = youtubeIdOf(widget.url);
    if (id != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Back',
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Video',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (controller == null)
              ColoredBox(
                color: AppColors.page,
                child: const EmptyState(
                  icon: Icons.videocam_off_outlined,
                  title: 'Video not available',
                  body: 'This link is not a YouTube video.',
                ),
              )
            else
              YoutubePlayer(controller: controller),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.amberLight,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => openExternalLink(context, widget.url),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open in YouTube'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
