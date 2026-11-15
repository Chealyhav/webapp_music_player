import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/song.dart';

enum AudioLogLevel { debug, info, warning, error }

enum AudioLogCategory { playback, api, convertAudio, playlist, player }

class AudioLogEntry {
  final DateTime timestamp;
  final AudioLogLevel level;
  final AudioLogCategory category;
  final String tag;
  final String message;
  final Map<String, dynamic>? data;
  final Object? error;
  final StackTrace? stackTrace;

  AudioLogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.tag,
    required this.message,
    this.data,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
    return '[$timeStr][${level.name.toUpperCase()}][${category.name}][$tag] $message';
  }
}

class TrackErrorDetails {
  final DateTime timestamp;
  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final String? audioUrl;
  final String failureStage;
  final String errorMessage;
  final Object? error;
  final StackTrace? stackTrace;
  final List<String> attemptedMethods;
  final Map<String, dynamic> diagnostics;

  TrackErrorDetails({
    required this.timestamp,
    required this.trackId,
    required this.trackTitle,
    required this.trackArtist,
    this.audioUrl,
    required this.failureStage,
    required this.errorMessage,
    this.error,
    this.stackTrace,
    this.attemptedMethods = const [],
    this.diagnostics = const {},
  });

  @override
  String toString() {
    return 'TrackErrorDetails(track: "$trackTitle" ($trackId), stage: $failureStage, error: $errorMessage)';
  }
}

class AudioLogger {
  static const int _maxLogs = 300;
  static const int _maxErrors = 50;

  static final List<AudioLogEntry> _logs = [];
  static final List<TrackErrorDetails> _trackErrors = [];

  static final StreamController<AudioLogEntry> _logStreamController =
      StreamController<AudioLogEntry>.broadcast();
  static final StreamController<TrackErrorDetails> _errorStreamController =
      StreamController<TrackErrorDetails>.broadcast();

  static List<AudioLogEntry> get recentLogs => List.unmodifiable(_logs);
  static List<TrackErrorDetails> get recentErrors =>
      List.unmodifiable(_trackErrors);

  static Stream<AudioLogEntry> get onLog => _logStreamController.stream;
  static Stream<TrackErrorDetails> get onError => _errorStreamController.stream;

  static void _addLog(AudioLogEntry entry) {
    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(entry);
    _logStreamController.add(entry);
  }

  static void logInfo(String tag, String message, {Map<String, dynamic>? data}) {
    final entry = AudioLogEntry(
      timestamp: DateTime.now(),
      level: AudioLogLevel.info,
      category: AudioLogCategory.playback,
      tag: tag,
      message: message,
      data: data,
    );
    _addLog(entry);
    debugPrint(entry.toString());
  }

  static void logWarning(String tag, String message, {Map<String, dynamic>? data}) {
    final entry = AudioLogEntry(
      timestamp: DateTime.now(),
      level: AudioLogLevel.warning,
      category: AudioLogCategory.playback,
      tag: tag,
      message: message,
      data: data,
    );
    _addLog(entry);
    debugPrint('⚠️ ${entry.toString()}');
  }

  static void logPlaylistEvent({
    required String event,
    required String playlistId,
    String? playlistName,
    int? songCount,
    Song? song,
    String? extra,
  }) {
    final msg =
        'Event: $event | Playlist: "${playlistName ?? playlistId}" (ID: $playlistId) | Count: ${songCount ?? 'N/A'}${song != null ? ' | Song: "${song.title}" (${song.id})' : ''}${extra != null ? ' | Details: $extra' : ''}';
    final entry = AudioLogEntry(
      timestamp: DateTime.now(),
      level: AudioLogLevel.info,
      category: AudioLogCategory.playlist,
      tag: 'PLAYLIST',
      message: msg,
      data: {
        'event': event,
        'playlistId': playlistId,
        'playlistName': playlistName,
        'songCount': songCount,
        'songId': song?.id,
        'songTitle': song?.title,
      },
    );
    _addLog(entry);
    debugPrint('🎵 ${entry.toString()}');
  }

  static void logConvertAudioSuccess({
    required String videoId,
    String? trackTitle,
    required String method,
    required String streamUrl,
    int? bitrate,
    Duration? elapsed,
  }) {
    final preview = streamUrl.substring(0, min(80, streamUrl.length));
    final msg =
        'SUCCESS via $method for ID: $videoId${trackTitle != null ? ' ("$trackTitle")' : ''} | Bitrate: ${bitrate ?? 'unknown'} | URL: $preview...${elapsed != null ? ' in ${elapsed.inMilliseconds}ms' : ''}';
    final entry = AudioLogEntry(
      timestamp: DateTime.now(),
      level: AudioLogLevel.info,
      category: AudioLogCategory.convertAudio,
      tag: 'CONVERT_AUDIO_SUCCESS',
      message: msg,
      data: {
        'videoId': videoId,
        'trackTitle': trackTitle,
        'method': method,
        'bitrate': bitrate,
        'elapsedMs': elapsed?.inMilliseconds,
      },
    );
    _addLog(entry);
    debugPrint('✅ ${entry.toString()}');
  }

  static void logConvertAudioError({
    required String videoId,
    String? trackTitle,
    required String method,
    required dynamic error,
    int? statusCode,
    String? responseBody,
    StackTrace? stackTrace,
  }) {
    final statusStr = statusCode != null ? ' [HTTP $statusCode]' : '';
    final bodySnippet = responseBody != null && responseBody.isNotEmpty
        ? ' | Response: ${responseBody.substring(0, min(120, responseBody.length))}'
        : '';
    final msg =
        'FAILED via $method for ID: $videoId${trackTitle != null ? ' ("$trackTitle")' : ''}$statusStr | Error: $error$bodySnippet';
    final entry = AudioLogEntry(
      timestamp: DateTime.now(),
      level: AudioLogLevel.error,
      category: AudioLogCategory.convertAudio,
      tag: 'CONVERT_AUDIO_ERROR',
      message: msg,
      error: error,
      stackTrace: stackTrace,
      data: {
        'videoId': videoId,
        'trackTitle': trackTitle,
        'method': method,
        'statusCode': statusCode,
      },
    );
    _addLog(entry);

    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      '❌ [CONVERT_AUDIO_ERROR]\n'
      '   Video ID:  $videoId\n'
      '   Track:     ${trackTitle ?? 'Unknown'}\n'
      '   Method:    $method\n'
      '   Status:    ${statusCode ?? 'N/A'}\n'
      '   Error:     $error\n'
      '${responseBody != null && responseBody.isNotEmpty ? '   Body:      ${responseBody.substring(0, min(200, responseBody.length))}\n' : ''}'
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
  }

  static void logTrackError(TrackErrorDetails details) {
    if (_trackErrors.length >= _maxErrors) {
      _trackErrors.removeAt(0);
    }
    _trackErrors.add(details);
    _errorStreamController.add(details);

    final entry = AudioLogEntry(
      timestamp: details.timestamp,
      level: AudioLogLevel.error,
      category: AudioLogCategory.player,
      tag: 'TRACK_ERROR',
      message:
          'Track failed: "${details.trackTitle}" (${details.trackId}) at stage ${details.failureStage}: ${details.errorMessage}',
      error: details.error,
      stackTrace: details.stackTrace,
      data: details.diagnostics,
    );
    _addLog(entry);

    debugPrint(
      '╔════════════════════════════════════════════════════════════╗\n'
      '║ ❌ [TRACK_PLAYBACK_ERROR]\n'
      '║ Track:     "${details.trackTitle}" (ID: ${details.trackId})\n'
      '║ Artist:    ${details.trackArtist}\n'
      '║ Audio URL: ${details.audioUrl ?? 'none'}\n'
      '║ Stage:     ${details.failureStage}\n'
      '║ Error:     ${details.errorMessage}\n'
      '║ Methods:   ${details.attemptedMethods.join(' -> ')}\n'
      '╚════════════════════════════════════════════════════════════╝',
    );
  }

  static void clearLogs() {
    _logs.clear();
    _trackErrors.clear();
  }
}
