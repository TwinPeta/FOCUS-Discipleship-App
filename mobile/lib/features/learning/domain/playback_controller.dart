import 'dart:async';

import 'package:flutter/foundation.dart';

/// Video playback seam. Only a fake exists; a real player (e.g.
/// `video_player`) can implement this later without touching the screen.
abstract class PlaybackController extends ChangeNotifier {
  Duration get position;
  Duration get duration;
  bool get isPlaying;

  /// Data saver: lower quality and no autoplay.
  bool get dataSaver;
  set dataSaver(bool value);

  void play();
  void pause();
  void seek(Duration position);
}

/// Simulates playback: advances the position once per [tick] while playing
/// and stops at the end.
class FakePlaybackController extends PlaybackController {
  FakePlaybackController({
    required this.duration,
    Duration start = Duration.zero,
    bool dataSaver = false,
    this.tick = const Duration(seconds: 1),
  }) : _position = start,
       _saver = dataSaver;

  final Duration tick;
  @override
  final Duration duration;
  Duration _position;
  bool _saver;
  Timer? _timer;

  @override
  Duration get position => _position;
  @override
  bool get isPlaying => _timer != null;
  @override
  bool get dataSaver => _saver;

  @override
  set dataSaver(bool value) {
    _saver = value;
    notifyListeners();
  }

  @override
  void play() {
    if (isPlaying) return;
    if (_position >= duration) _position = Duration.zero;
    _timer = Timer.periodic(tick, (_) {
      _position += tick;
      if (_position >= duration) {
        _position = duration;
        pause();
        return;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void pause() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void seek(Duration position) {
    _position = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
