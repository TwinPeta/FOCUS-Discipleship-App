import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../learning/domain/learning_models.dart';
import '../../../learning/domain/playback_controller.dart';
import '../../domain/testimony.dart';

/// A story's video (screen 53). Nothing downloads until the reader taps
/// play, so scrolling past a story costs no data.
class StoryVideo extends ConsumerStatefulWidget {
  const StoryVideo({super.key, required this.testimony});

  final Testimony testimony;

  @override
  ConsumerState<StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends ConsumerState<StoryVideo> {
  PlaybackController? _player;
  bool _opening = false;
  bool _unavailable = false;

  Duration get _length {
    final parts = (widget.testimony.duration ?? '').split(':');
    if (parts.length != 2) return const Duration(minutes: 2);
    return Duration(
      minutes: int.tryParse(parts[0]) ?? 0,
      seconds: int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<void> _toggle() async {
    final p = _player;
    if (p != null) {
      p.isPlaying ? p.pause() : p.play();
      return;
    }
    setState(() => _opening = true);
    try {
      final t = widget.testimony;
      final opened = await ref.read(playbackFactoryProvider)(
        VideoContent(
          item: LearningItem(
            id: t.id,
            kind: LearningKind.video,
            title: t.title,
            description: '',
          ),
          duration: _length,
          streamUrl: t.videoUrl,
        ),
        start: Duration.zero,
        dataSaver: false,
      );
      if (!mounted) {
        opened.dispose();
        return;
      }
      opened.addListener(_changed);
      setState(() {
        _player = opened;
        _opening = false;
      });
      opened.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _opening = false;
          _unavailable = true;
        });
      }
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player
      ?..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = _player;
    final playing = p?.isPlaying ?? false;
    final total = p != null && p.duration > Duration.zero
        ? p.duration
        : _length;
    final label = p == null
        ? _clock(total)
        : '${_clock(p.position)} / ${_clock(total)}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.cardSmall),
      child: Container(
        height: 200,
        color: AppColors.honey,
        child: Stack(
          children: [
            if (p != null) Positioned.fill(child: p.surface),
            if (_unavailable)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'This video can\'t be played right now. Try again later.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
              )
            else
              Center(
                child: Semantics(
                  button: true,
                  label: playing ? 'Pause video' : 'Play video',
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.white,
                    shape: CircleBorder(
                      side: BorderSide(color: AppColors.ink, width: 2.5),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _opening ? null : () => unawaited(_toggle()),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: _opening
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.ink,
                                ),
                              )
                            : Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 34,
                                color: AppColors.ink,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.chip.copyWith(
                    color: AppColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
