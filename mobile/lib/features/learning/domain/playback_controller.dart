import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'learning_models.dart';

/// Video playback seam: the screen only talks to this.
abstract class PlaybackController extends ChangeNotifier {
  Duration get position;
  Duration get duration;
  bool get isPlaying;

  /// Data saver: no autoplay (and the screen pauses when it is turned on).
  bool get dataSaver;
  set dataSaver(bool value);

  /// The picture. Empty for controllers that have none.
  Widget get surface;

  void play();
  void pause();
  void seek(Duration position);
}

/// Plays the video from its stream address with the platform player
/// (AVPlayer on iOS, ExoPlayer on Android; HLS and MP4 both work).
class NetworkPlaybackController extends PlaybackController {
  NetworkPlaybackController._(this._video, {required bool dataSaver})
    : _saver = dataSaver {
    _video.addListener(notifyListeners);
  }

  /// Opens [url] and starts at [start]. Throws if it cannot be loaded.
  static Future<NetworkPlaybackController> open(
    Uri url, {
    Duration start = Duration.zero,
    bool dataSaver = false,
  }) async {
    final video = VideoPlayerController.networkUrl(url);
    try {
      await video.initialize();
      if (start > Duration.zero && start < video.value.duration) {
        await video.seekTo(start);
      }
    } catch (_) {
      await video.dispose();
      rethrow;
    }
    return NetworkPlaybackController._(video, dataSaver: dataSaver);
  }

  final VideoPlayerController _video;
  bool _saver;

  @override
  Duration get position => _video.value.position;
  @override
  Duration get duration => _video.value.duration;
  @override
  bool get isPlaying => _video.value.isPlaying;
  @override
  bool get dataSaver => _saver;

  @override
  set dataSaver(bool value) {
    _saver = value;
    notifyListeners();
  }

  @override
  Widget get surface => Center(
    child: AspectRatio(
      aspectRatio: _video.value.aspectRatio == 0
          ? 16 / 9
          : _video.value.aspectRatio,
      child: VideoPlayer(_video),
    ),
  );

  @override
  void play() => unawaited(_video.play());
  @override
  void pause() => unawaited(_video.pause());
  @override
  void seek(Duration position) => unawaited(_video.seekTo(position));

  @override
  void dispose() {
    _video
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}

/// The video has no stream address yet (or it cannot be opened).
class VideoUnavailable implements Exception {
  const VideoUnavailable();
}

/// Opens the player for a video. Tests swap this for a scripted one.
typedef PlaybackFactory = Future<PlaybackController> Function(
  VideoContent video, {
  required Duration start,
  required bool dataSaver,
});

final playbackFactoryProvider = Provider<PlaybackFactory>(
  (ref) => (video, {required start, required dataSaver}) async {
    final url = video.streamUrl;
    if (url == null || url.isEmpty) {
      throw const VideoUnavailable();
    }
    return NetworkPlaybackController.open(
      Uri.parse(url),
      start: start,
      dataSaver: dataSaver,
    );
  },
);
