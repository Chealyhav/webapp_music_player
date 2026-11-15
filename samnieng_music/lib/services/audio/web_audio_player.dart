// Web-only audio player backed by youtube_player_iframe.
// On native (Android/iOS/desktop) this file is never imported;
// only AudioPlayerService imports it via conditional logic.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/utils/audio_logger.dart';
import '../../data/models/song.dart';

/// A thin wrapper around [YoutubePlayerController] that exposes the same
/// position/duration/playing streams used by [AudioPlayerService] on web.
class WebAudioPlayer {
  YoutubePlayerController? _controller;
  Song? _currentSong;

  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  Timer? _pollTimer;

  YoutubePlayerController? get controller => _controller;
  Song? get currentSong => _currentSong;

  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;

  /// Load and start playing [song] via the YouTube iframe player.
  /// Returns the controller so the UI can embed it (or use it headlessly).
  YoutubePlayerController load(Song song) {
    _stopPoll();
    _currentSong = song;

    final videoId =
        song.audioUrl.isNotEmpty ? song.audioUrl : song.id;

    AudioLogger.logInfo(
      'WEB_PLAYER',
      'calling playVideo for videoId=$videoId',
    );

    if (_controller != null) {
      // Reuse controller, just load the new video
      _controller!.loadVideoById(videoId: videoId, startSeconds: 0);
    } else {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: false,
          loop: false,
          strictRelatedVideos: true,
        ),
      );
    }

    _startPoll();
    return _controller!;
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final ctrl = _controller;
      if (ctrl == null) return;
      try {
        final pos = await ctrl.currentTime;
        final dur = await ctrl.duration;
        final state = await ctrl.playerState;

        final isPlaying = state == PlayerState.playing;
        if (!_playingController.isClosed) {
          _playingController.add(isPlaying);
        }
        if (!_positionController.isClosed) {
          _positionController.add(Duration(milliseconds: (pos * 1000).round()));
        }
        if (!_durationController.isClosed && dur > 0) {
          _durationController
              .add(Duration(milliseconds: (dur * 1000).round()));
        }
      } catch (_) {}
    });
  }

  void _stopPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> play() async {
    await _controller?.playVideo();
    _playingController.add(true);
  }

  Future<void> pause() async {
    await _controller?.pauseVideo();
    _playingController.add(false);
  }

  Future<void> stop() async {
    await _controller?.stopVideo();
    _playingController.add(false);
  }

  Future<void> seek(Duration position) async {
    await _controller?.seekTo(
      seconds: position.inSeconds.toDouble(),
      allowSeekAhead: true,
    );
  }

  bool get isAvailable => kIsWeb;

  void dispose() {
    _stopPoll();
    _controller?.close();
    _controller = null;
    _playingController.close();
    _positionController.close();
    _durationController.close();
  }
}
