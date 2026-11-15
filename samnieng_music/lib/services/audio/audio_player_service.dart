import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/utils/audio_logger.dart';
import '../../data/datasources/remote/youtube_datasource.dart';
import '../../data/models/song.dart';
import 'web_audio_player.dart';

class AudioPlayerService {
  // ── Native (Android / iOS / Desktop / Windows) ──────────────────────────
  final AudioPlayer _nativePlayer;
  final YoutubeDatasource _youtubeDatasource;
  StreamSubscription? _nativeEventSub;

  // ── Web (iframe bridge) ──────────────────────────────────────────────────
  final WebAudioPlayer _webPlayer = WebAudioPlayer();

  TrackErrorDetails? _lastError;
  final StreamController<TrackErrorDetails> _errorController =
      StreamController<TrackErrorDetails>.broadcast();

  // ── Completion detection (web) ───────────────────────────────────────────
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();
  StreamSubscription? _webCompletionSub;
  Duration? _lastDuration;
  bool _completionFired = false;

  AudioPlayerService({
    AudioPlayer? player,
    YoutubeDatasource? youtubeDatasource,
  }) : _nativePlayer = player ?? AudioPlayer(),
       _youtubeDatasource = youtubeDatasource ?? YoutubeDatasource() {
    _initNativeErrorListener();
    if (kIsWeb) _initWebCompletionDetection();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public getters
  // ─────────────────────────────────────────────────────────────────────────

  /// The raw native player (for non-web builds only).
  AudioPlayer get nativePlayer => _nativePlayer;

  /// The web iframe player controller (for web only — used to embed the
  /// player widget in the tree so the browser allows audio autoplay).
  WebAudioPlayer get webPlayer => _webPlayer;

  TrackErrorDetails? get lastError => _lastError;
  Stream<TrackErrorDetails> get playbackErrorStream => _errorController.stream;

  // ── Platform-unified streams ─────────────────────────────────────────────

  Stream<bool> get playerStateStream => kIsWeb
      ? _webPlayer.playingStream
      : _nativePlayer.playerStateStream.map((s) => s.playing);

  Stream<Duration> get positionStream => kIsWeb
      ? _webPlayer.positionStream
      : _nativePlayer.positionStream.map((p) => p ?? Duration.zero);

  Stream<Duration?> get durationStream =>
      kIsWeb ? _webPlayer.durationStream : _nativePlayer.durationStream;

  /// Fires once when the current track finishes (both platforms).
  Stream<void> get completionStream => kIsWeb
      ? _completionController.stream
      : _nativePlayer.playerStateStream
            .where(
              (s) =>
                  s.processingState == ProcessingState.completed && s.playing,
            )
            .map((_) => null);

  /// Combined processing-state stream (compatible with [autoAdvanceProvider]).
  Stream<ProcessingState> get processingStateStream => kIsWeb
      ? _completionController.stream.map((_) => ProcessingState.completed)
      : _nativePlayer.playerStateStream.map((s) => s.processingState);

  // ─────────────────────────────────────────────────────────────────────────
  // Initialisation helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _initNativeErrorListener() {
    _nativeEventSub = _nativePlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace stack) {
        AudioLogger.logWarning(
          'PLAYER_STREAM',
          'Native playback event stream error: $e',
        );
      },
    );
  }

  /// On web we detect track completion by watching position near-equal to
  /// duration (iframe doesn't expose a clean "ended" event easily from Dart).
  void _initWebCompletionDetection() {
    Duration? _lastPos;
    _webCompletionSub = _webPlayer.positionStream.listen((pos) async {
      if (_completionFired) return;
      final dur = _lastDuration;
      if (dur == null || dur.inSeconds < 2) return;
      // If position is within 1.5s of duration and not moving → completed
      if (pos.inMilliseconds >= dur.inMilliseconds - 1500 &&
          _lastPos != null &&
          (pos - _lastPos!).abs().inMilliseconds < 600) {
        _completionFired = true;
        _completionController.add(null);
        AudioLogger.logInfo(
          'WEB_PLAYER',
          'Track completion detected via position polling',
        );
      }
      _lastPos = pos;
    });

    _webPlayer.durationStream.listen((d) {
      if (d != null && d > Duration.zero) {
        _lastDuration = d;
        _completionFired = false; // reset for next track
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core playback
  // ─────────────────────────────────────────────────────────────────────────

  /// Plays [song].  Returns `true` on success, `false` on failure.
  Future<bool> playSong(Song song) async {
    final startedAt = DateTime.now();
    final attemptedMethods = <String>[];

    AudioLogger.logInfo(
      'PLAYBACK',
      'Request to play song: "${song.title}" by "${song.artist}" (ID: ${song.id})',
    );

    try {
      // ── WEB PATH ─────────────────────────────────────────────────────────
      if (kIsWeb) {
        AudioLogger.logInfo(
          'PLAYBACK_WEB',
          'Web mode detected; YouTube iframe player will handle playback for "${song.title}"',
        );
        attemptedMethods.add('WebAudioPlayer.load');
        _completionFired = false;
        _lastDuration = null;
        _webPlayer.load(song);
        _lastError = null;
        return true;
      }

      // ── NATIVE PATH ───────────────────────────────────────────────────────
      AudioLogger.logInfo(
        'PLAYBACK',
        'Stopping current audio player playback...',
      );
      await _nativePlayer.stop();

      final identifier = song.audioUrl.isNotEmpty ? song.audioUrl : song.id;

      String? playUrl;
      final isDirectAudio =
          identifier.startsWith('http') &&
          (identifier.endsWith('.mp3') ||
              identifier.endsWith('.m4a') ||
              identifier.endsWith('.wav') ||
              identifier.endsWith('.ogg') ||
              identifier.endsWith('.aac'));

      if (isDirectAudio) {
        attemptedMethods.add('DirectAudioFile');
        AudioLogger.logInfo(
          'PLAYBACK',
          'Direct audio file URL detected for "${song.title}": $identifier',
        );
        playUrl = identifier;
      } else {
        attemptedMethods.add('YouTubeDatasource.getAudioStreamUrl');
        AudioLogger.logInfo(
          'PLAYBACK',
          'Calling API / Datasource to resolve and convert audio stream for "${song.title}" ($identifier)',
        );
        playUrl = await _youtubeDatasource.getAudioStreamUrl(
          identifier,
          trackTitle: song.title,
          trackArtist: song.artist,
        );
      }

      if (playUrl == null || playUrl.isEmpty) {
        final errorDetails = TrackErrorDetails(
          timestamp: DateTime.now(),
          trackId: song.id,
          trackTitle: song.title,
          trackArtist: song.artist,
          audioUrl: song.audioUrl,
          failureStage: 'API_AUDIO_CONVERSION',
          errorMessage:
              'Failed to resolve/convert audio stream URL for "${song.title}". All conversion methods failed.',
          attemptedMethods: attemptedMethods,
          diagnostics: {
            'identifier': identifier,
            'isDirectAudio': isDirectAudio,
            'timeElapsedMs': DateTime.now()
                .difference(startedAt)
                .inMilliseconds,
          },
        );
        AudioLogger.logTrackError(errorDetails);
        _lastError = errorDetails;
        _errorController.add(errorDetails);
        return false;
      }

      AudioLogger.logInfo(
        'PLAYBACK',
        'Setting AudioSource with stream URL: ${playUrl.substring(0, min(80, playUrl.length))}...',
      );

      attemptedMethods.add('AudioSource.uri');
      AudioSource createAudioSource(String url) => AudioSource.uri(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
        },
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album ?? 'YouTube',
          artUri: song.artworkUrl != null
              ? Uri.tryParse(song.artworkUrl!)
              : null,
          duration: song.duration > Duration.zero ? song.duration : null,
        ),
      );

      attemptedMethods.add('player.setAudioSource');
      try {
        await _nativePlayer.setAudioSource(createAudioSource(playUrl));
      } catch (primaryError, primaryStack) {
        if (isDirectAudio) {
          Error.throwWithStackTrace(primaryError, primaryStack);
        }

        AudioLogger.logWarning(
          'PLAYBACK',
          'Primary stream rejected for ${song.id}; trying alternate stream providers: $primaryError',
        );
        _youtubeDatasource.invalidateCache(identifier);
        attemptedMethods.add('AlternateStreamProviders');
        final fallbackUrl = await _youtubeDatasource.getAudioStreamUrl(
          identifier,
          trackTitle: song.title,
          trackArtist: song.artist,
          skipYouTubeExplode: true,
        );

        if (fallbackUrl == null ||
            fallbackUrl.isEmpty ||
            fallbackUrl == playUrl) {
          Error.throwWithStackTrace(primaryError, primaryStack);
        }

        AudioLogger.logInfo(
          'PLAYBACK',
          'Retrying rejected stream with an alternate provider.',
        );
        attemptedMethods.add('player.setAudioSource(fallback)');
        await _nativePlayer.setAudioSource(createAudioSource(fallbackUrl));
      }

      attemptedMethods.add('player.play');
      await _nativePlayer.play();

      final totalMs = DateTime.now().difference(startedAt).inMilliseconds;
      AudioLogger.logInfo(
        'PLAYBACK_SUCCESS',
        'Successfully playing "${song.title}" after ${totalMs}ms',
      );

      _lastError = null;
      return true;
    } catch (e, stack) {
      final identifier = song.audioUrl.isNotEmpty ? song.audioUrl : song.id;
      if (!kIsWeb) _youtubeDatasource.invalidateCache(identifier);
      if (!kIsWeb) {
        try {
          await _nativePlayer.stop();
        } catch (stopError, stopStack) {
          AudioLogger.logWarning(
            'PLAYBACK',
            'Could not stop player after playback failure: $stopError\n$stopStack',
          );
        }
      }

      final errorDetails = TrackErrorDetails(
        timestamp: DateTime.now(),
        trackId: song.id,
        trackTitle: song.title,
        trackArtist: song.artist,
        audioUrl: song.audioUrl,
        failureStage: attemptedMethods.isNotEmpty
            ? attemptedMethods.last
            : 'AUDIO_PLAYBACK_EXCEPTION',
        errorMessage: 'Playback exception: $e',
        error: e,
        stackTrace: stack,
        attemptedMethods: attemptedMethods,
        diagnostics: {
          'identifier': identifier,
          'platform': kIsWeb ? 'web' : 'native',
          'timeElapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
        },
      );

      AudioLogger.logTrackError(errorDetails);
      _lastError = errorDetails;
      _errorController.add(errorDetails);
      return false;
    }
  }

  Future<void> pause() async {
    if (kIsWeb) {
      await _webPlayer.pause();
    } else {
      await _nativePlayer.pause();
    }
  }

  Future<void> resume() async {
    if (kIsWeb) {
      await _webPlayer.play();
    } else {
      await _nativePlayer.play();
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      await _webPlayer.stop();
    } else {
      await _nativePlayer.stop();
    }
  }

  Future<void> seek(Duration position) async {
    if (kIsWeb) {
      await _webPlayer.seek(position);
    } else {
      await _nativePlayer.seek(position);
    }
  }

  Future<void> setVolume(double volume) async {
    if (!kIsWeb) {
      await _nativePlayer.setVolume(volume.clamp(0.0, 1.0));
    }
    // Web: YouTube iframe has its own volume control; skip for now
  }

  void dispose() {
    _nativeEventSub?.cancel();
    _webCompletionSub?.cancel();
    _errorController.close();
    _completionController.close();
    _webPlayer.dispose();
    _nativePlayer.dispose();
  }
}
