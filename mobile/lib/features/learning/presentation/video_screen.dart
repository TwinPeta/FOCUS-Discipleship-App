import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../data/learning_repository.dart';
import '../domain/learning_models.dart';
import '../domain/playback_controller.dart';
import 'learning_providers.dart';
import 'widgets/viewer_parts.dart';

/// Data saver preference (lower quality, no autoplay), shared by videos.
final dataSaverProvider = StateProvider<bool>((ref) => false);

/// Screen 33: Video (`/resources/video/:id`). Plays the stream through
/// [PlaybackController]; the resume position is remembered.
class VideoScreen extends ConsumerWidget {
  const VideoScreen({super.key, required this.id, required this.origin});

  final String id;
  final LearningOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(videoContentProvider(id))
        .when(
          loading: () =>
              const Scaffold(backgroundColor: AppColors.page, body: Skeleton()),
          error: (e, s) => ErrorScreen(
            onRetry: () => ref.invalidate(videoContentProvider(id)),
          ),
          data: (video) => _VideoView(video: video, origin: origin),
        );
  }
}

class _VideoView extends ConsumerStatefulWidget {
  const _VideoView({required this.video, required this.origin});

  final VideoContent video;
  final LearningOrigin origin;

  @override
  ConsumerState<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends ConsumerState<_VideoView> {
  PlaybackController? _player;
  bool _unavailable = false;
  late final LearningRepository _repo = ref.read(learningRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final start = await _repo.getResumePosition(widget.video.item.id);
    if (!mounted) return;
    final dataSaver = ref.read(dataSaverProvider);
    final PlaybackController player;
    try {
      player = await ref.read(playbackFactoryProvider)(
        widget.video,
        start: start,
        dataSaver: dataSaver,
      );
    } catch (_) {
      if (mounted) setState(() => _unavailable = true);
      return;
    }
    if (!mounted) {
      player.dispose();
      return;
    }
    player.addListener(_onTick);
    setState(() => _player = player);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!dataSaver && !reduceMotion) player.play();
  }

  void _onTick() => setState(() {});

  @override
  void dispose() {
    final player = _player;
    if (player != null) {
      // Remember where the user stopped (repository captured in initState;
      // no ref use after dispose).
      _repo.saveResumePosition(widget.video.item.id, player.position).ignore();
      player
        ..removeListener(_onTick)
        ..dispose();
    }
    super.dispose();
  }

  void _setDataSaver(bool value) {
    ref.read(dataSaverProvider.notifier).state = value;
    final player = _player;
    if (player == null) return;
    player.dataSaver = value;
    if (value) player.pause();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.video.item;
    final dataSaver = ref.watch(dataSaverProvider);
    return ViewerScaffold(
      origin: widget.origin,
      itemId: item.id,
      hero: _Player(
        player: _player,
        unavailable: _unavailable,
        onBack: () => leaveViewer(context, widget.origin),
      ),
      chips: viewerChips('Video', topic: item.topicLabel),
      title: item.title,
      content: [
        Text(item.description, style: AppTextStyles.body),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quality', style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text(
                dataSaver
                    ? 'Data saver: lower quality, no autoplay.'
                    : 'Auto: best quality for your connection.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 10),
              SegmentedToggle<bool>(
                value: dataSaver,
                options: const [
                  SegmentedOption(label: 'Auto', value: false),
                  SegmentedOption(label: 'Data saver', value: true),
                ],
                onChanged: _setDataSaver,
              ),
            ],
          ),
        ),
      ],
      bottom: CompleteButton(
        label: 'Mark as complete',
        item: item,
        origin: widget.origin,
      ),
    );
  }
}

String _clock(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// 230px player: back button, central play/pause, progress bar and time.
class _Player extends StatelessWidget {
  const _Player({
    required this.player,
    required this.onBack,
    this.unavailable = false,
  });

  final PlaybackController? player;
  final bool unavailable;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final progress = p == null || p.duration == Duration.zero
        ? 0.0
        : p.position.inMilliseconds / p.duration.inMilliseconds;
    final playing = p?.isPlaying ?? false;
    return Container(
      height: 230,
      color: AppColors.honey,
      child: Stack(
        children: [
          if (p != null) Positioned.fill(child: p.surface),
          if (unavailable)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'This video can\'t be played right now. Try again later.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle,
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: RoundIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              onPressed: onBack,
            ),
          ),
          Center(
            child: Semantics(
              button: true,
              label: playing ? 'Pause video' : 'Play video',
              excludeSemantics: true,
              child: Material(
                color: AppColors.white,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.ink, width: 2.5),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: p == null ? null : (playing ? p.pause : p.play),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 36,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    p == null
                        ? '--:-- / --:--'
                        : '${_clock(p.position)} / ${_clock(p.duration)}',
                    style: AppTextStyles.chip,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Video progress',
                  value: '${(progress * 100).round()} percent',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          Container(color: AppColors.white),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0, 1).toDouble(),
                            child: Container(color: AppColors.amber),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
