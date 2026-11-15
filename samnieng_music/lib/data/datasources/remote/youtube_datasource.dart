import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/audio_logger.dart';

class YoutubeDatasource {
  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, String> _streamCache = {};

  String get _apiKey {
    final key = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw StateError('YOUTUBE_API_KEY is missing. Set it in .env');
    }
    return key;
  }

  /// Invalidate cached stream URL for a given video ID or URL
  void invalidateCache(String videoIdOrUrl) {
    final videoId = extractVideoId(videoIdOrUrl) ?? videoIdOrUrl.trim();
    if (_streamCache.remove(videoId) != null) {
      AudioLogger.logInfo(
        'CACHE',
        'Invalidated cached audio stream URL for videoId: $videoId',
      );
    }
  }

  /// Extracts standard 11-character video ID from ID or full YouTube URL
  String? extractVideoId(String videoIdOrUrl) {
    final trimmed = videoIdOrUrl.trim();
    if (trimmed.isEmpty) return null;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;

    try {
      final uri = Uri.parse(trimmed);
      if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }
    } catch (_) {}

    final reg = RegExp(r'(?:(?:v=)|(?:be/)|(?:embed/))([a-zA-Z0-9_-]{11})');
    final match = reg.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  /// Fetches direct audio stream URL with fallback and cache.
  Future<String?> getAudioStreamUrl(
    String videoIdOrUrl, {
    String? trackTitle,
    String? trackArtist,
    bool skipYouTubeExplode = false,
  }) async {
    final startTime = DateTime.now();
    final videoId = extractVideoId(videoIdOrUrl);
    if (videoId == null) {
      if (videoIdOrUrl.startsWith('http://') ||
          videoIdOrUrl.startsWith('https://')) {
        AudioLogger.logInfo(
          'STREAM_RESOLVE',
          'Identifier is already a direct URL: $videoIdOrUrl',
        );
        return videoIdOrUrl;
      }
      AudioLogger.logConvertAudioError(
        videoId: videoIdOrUrl,
        trackTitle: trackTitle,
        method: 'extractVideoId',
        error: 'Invalid YouTube video ID or URL format: "$videoIdOrUrl"',
      );
      return null;
    }

    if (_streamCache.containsKey(videoId)) {
      final cachedUrl = _streamCache[videoId]!;
      AudioLogger.logInfo(
        'STREAM_RESOLVE',
        'Cache hit for videoId: $videoId -> ${cachedUrl.substring(0, min(60, cachedUrl.length))}...',
      );
      return cachedUrl;
    }

    AudioLogger.logInfo(
      'STREAM_RESOLVE',
      'Starting audio resolution/conversion for videoId: $videoId (Title: "${trackTitle ?? 'unknown'}")',
    );

    if (!skipYouTubeExplode) {
      // Method 1: YouTube Explode client
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(videoId);

        if (manifest.audioOnly.isNotEmpty) {
          final streamInfo = manifest.audioOnly.withHighestBitrate();
          final url = streamInfo.url.toString();
          _streamCache[videoId] = url;
          AudioLogger.logConvertAudioSuccess(
            videoId: videoId,
            trackTitle: trackTitle,
            method: 'YouTubeExplode(audioOnly)',
            streamUrl: url,
            bitrate: (streamInfo.bitrate.bitsPerSecond / 1000).round(),
            elapsed: DateTime.now().difference(startTime),
          );
          return url;
        }

        if (manifest.audio.isNotEmpty) {
          final streamInfo = manifest.audio.withHighestBitrate();
          final url = streamInfo.url.toString();
          _streamCache[videoId] = url;
          AudioLogger.logConvertAudioSuccess(
            videoId: videoId,
            trackTitle: trackTitle,
            method: 'YouTubeExplode(audio)',
            streamUrl: url,
            bitrate: (streamInfo.bitrate.bitsPerSecond / 1000).round(),
            elapsed: DateTime.now().difference(startTime),
          );
          return url;
        }

        if (manifest.muxed.isNotEmpty) {
          final streamInfo = manifest.muxed.withHighestBitrate();
          final url = streamInfo.url.toString();
          _streamCache[videoId] = url;
          AudioLogger.logConvertAudioSuccess(
            videoId: videoId,
            trackTitle: trackTitle,
            method: 'YouTubeExplode(muxed)',
            streamUrl: url,
            bitrate: (streamInfo.bitrate.bitsPerSecond / 1000).round(),
            elapsed: DateTime.now().difference(startTime),
          );
          return url;
        }

        AudioLogger.logConvertAudioError(
          videoId: videoId,
          trackTitle: trackTitle,
          method: 'YouTubeExplode.getManifest',
          error: 'Manifest returned 0 playable audio or muxed streams',
        );
      } catch (e, stack) {
        AudioLogger.logConvertAudioError(
          videoId: videoId,
          trackTitle: trackTitle,
          method: 'YouTubeExplode.getManifest',
          error: e,
          stackTrace: stack,
        );
      }
    } else {
      AudioLogger.logInfo(
        'STREAM_RESOLVE',
        'Skipping YouTubeExplode for $videoId after native stream playback failed.',
      );
    }

    // Method 2: Piped API endpoints fallback
    AudioLogger.logInfo(
      'STREAM_RESOLVE',
      'YouTube Explode failed for $videoId. Trying Piped API fallback endpoints...',
    );
    final pipedUrl = await _getPipedAudioStreamUrl(
      videoId,
      trackTitle: trackTitle,
    );
    if (pipedUrl != null && pipedUrl.isNotEmpty) {
      _streamCache[videoId] = pipedUrl;
      AudioLogger.logConvertAudioSuccess(
        videoId: videoId,
        trackTitle: trackTitle,
        method: 'PipedApi',
        streamUrl: pipedUrl,
        elapsed: DateTime.now().difference(startTime),
      );
      return pipedUrl;
    }

    // Method 3: Invidious API fallback
    AudioLogger.logInfo(
      'STREAM_RESOLVE',
      'Piped fallback failed for $videoId. Trying Invidious API fallback endpoints...',
    );
    final invidiousUrl = await _getInvidiousAudioStreamUrl(
      videoId,
      trackTitle: trackTitle,
    );
    if (invidiousUrl != null && invidiousUrl.isNotEmpty) {
      _streamCache[videoId] = invidiousUrl;
      AudioLogger.logConvertAudioSuccess(
        videoId: videoId,
        trackTitle: trackTitle,
        method: 'InvidiousApi',
        streamUrl: invidiousUrl,
        elapsed: DateTime.now().difference(startTime),
      );
      return invidiousUrl;
    }

    AudioLogger.logConvertAudioError(
      videoId: videoId,
      trackTitle: trackTitle,
      method: 'ALL_CONVERSION_METHODS',
      error:
          'CRITICAL: All audio extraction/conversion methods exhausted for videoId: $videoId. Cannot play track.',
    );
    return null;
  }

  Future<String?> _getPipedAudioStreamUrl(
    String videoId, {
    String? trackTitle,
  }) async {
    final endpoints = [
      'https://pipedapi.adminforge.de/streams/$videoId',
      'https://api.piped.privacydev.net/streams/$videoId',
      'https://pipedapi.leptons.xyz/streams/$videoId',
      'https://pipedapi.r4fo.com/streams/$videoId',
      'https://pipedapi.kavin.rocks/streams/$videoId',
      'https://piped.video/api/v1/streams/$videoId',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .get(
              Uri.parse(endpoint),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) {
          AudioLogger.logConvertAudioError(
            videoId: videoId,
            trackTitle: trackTitle,
            method: 'PipedApi: $endpoint',
            statusCode: response.statusCode,
            responseBody: response.body,
            error: 'HTTP status ${response.statusCode}',
          );
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }

        final audioStreams = <Map<String, dynamic>>[];
        final rawStreams = decoded['audioStreams'];
        if (rawStreams is List) {
          for (final item in rawStreams) {
            if (item is Map) {
              audioStreams.add(Map<String, dynamic>.from(item));
            }
          }
        }

        if (audioStreams.isEmpty) {
          final fallbackUrl = decoded['url'];
          if (fallbackUrl is String && fallbackUrl.isNotEmpty) {
            return fallbackUrl;
          }
          continue;
        }

        audioStreams.sort((a, b) {
          final aBitrate = (a['bitrate'] is num)
              ? (a['bitrate'] as num).toInt()
              : 0;
          final bBitrate = (b['bitrate'] is num)
              ? (b['bitrate'] as num).toInt()
              : 0;
          return bBitrate.compareTo(aBitrate);
        });

        final bestUrl = audioStreams.first['url']?.toString() ?? '';
        if (bestUrl.isNotEmpty) {
          return bestUrl;
        }
      } catch (e, stack) {
        AudioLogger.logConvertAudioError(
          videoId: videoId,
          trackTitle: trackTitle,
          method: 'PipedApi: $endpoint',
          error: e,
          stackTrace: stack,
        );
      }
    }

    return null;
  }

  Future<String?> _getInvidiousAudioStreamUrl(
    String videoId, {
    String? trackTitle,
  }) async {
    final instances = [
      'https://inv.nadeko.net/api/v1/videos/$videoId',
      'https://invidious.nerdvpn.de/api/v1/videos/$videoId',
      'https://vid.puffyan.us/api/v1/videos/$videoId',
    ];

    for (final urlStr in instances) {
      try {
        final response = await http
            .get(
              Uri.parse(urlStr),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) {
          AudioLogger.logConvertAudioError(
            videoId: videoId,
            trackTitle: trackTitle,
            method: 'InvidiousApi: $urlStr',
            statusCode: response.statusCode,
            responseBody: response.body,
            error: 'HTTP status ${response.statusCode}',
          );
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) continue;

        final adaptiveFormats = decoded['adaptiveFormats'];
        if (adaptiveFormats is List) {
          final audioList = <Map<String, dynamic>>[];
          for (final fmt in adaptiveFormats) {
            if (fmt is Map) {
              final type = (fmt['type'] ?? '').toString();
              if (type.startsWith('audio/')) {
                audioList.add(Map<String, dynamic>.from(fmt));
              }
            }
          }

          if (audioList.isNotEmpty) {
            audioList.sort((a, b) {
              final aBitrate = (a['bitrate'] is num)
                  ? (a['bitrate'] as num).toInt()
                  : 0;
              final bBitrate = (b['bitrate'] is num)
                  ? (b['bitrate'] as num).toInt()
                  : 0;
              return bBitrate.compareTo(aBitrate);
            });
            final streamUrl = audioList.first['url']?.toString() ?? '';
            if (streamUrl.isNotEmpty) {
              return streamUrl;
            }
          }
        }
      } catch (e) {
        AudioLogger.logConvertAudioError(
          videoId: videoId,
          trackTitle: trackTitle,
          method: 'InvidiousApi: $urlStr',
          error: e,
        );
      }
    }
    return null;
  }

  void dispose() {
    _yt.close();
  }

  // 1. search.list - Search for songs/videos
  Future<List<Song>> searchYoutube(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return [];

    final url = Uri.parse(
      '${AppConstants.youtubeBaseUrl}/search'
      '?part=snippet'
      '&q=${Uri.encodeComponent(normalizedQuery)}'
      '&type=video'
      '&videoCategoryId=10' // Music category
      '&maxResults=25'
      '&key=$_apiKey',
    );

    AudioLogger.logInfo('YOUTUBE_API', 'Search request: "$normalizedQuery"');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      AudioLogger.logWarning(
        'YOUTUBE_API',
        'Search failed with status ${response.statusCode}: ${response.body}',
      );
      throw StateError('YouTube API search failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];

    final songs = items
        .map<Song>((item) {
          final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
          final id = item['id'] as Map<String, dynamic>? ?? {};
          final videoId = (id['videoId'] ?? '').toString();
          final title = (snippet['title'] ?? 'Untitled').toString();
          final artist = (snippet['channelTitle'] ?? 'Unknown artist')
              .toString();
          final thumbnail =
              (snippet['thumbnails'] as Map<String, dynamic>?)?['high']
                  as Map<String, dynamic>? ??
              {};
          final imageUrl = (thumbnail['url'] ?? '').toString();

          return Song(
            id: videoId.isNotEmpty
                ? videoId
                : '${DateTime.now().millisecondsSinceEpoch}-$title',
            title: title,
            artist: artist,
            album: 'YouTube',
            artworkUrl: imageUrl.isNotEmpty ? imageUrl : null,
            audioUrl: videoId,
            duration: Duration.zero,
          );
        })
        .where((song) => song.id.isNotEmpty)
        .toList();

    return _hydrateDurations(songs);
  }

  // 2. videos.list - Get detailed video info (like duration)
  Future<Song?> getVideoDetails(String videoId) async {
    final url = Uri.parse(
      '${AppConstants.youtubeBaseUrl}/videos'
      '?part=snippet,contentDetails,statistics'
      '&id=$videoId'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      AudioLogger.logWarning(
        'YOUTUBE_API',
        'videos.list failed for $videoId: ${response.body}',
      );
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    if (items.isEmpty) return null;

    final item = items.first;
    final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
    final contentDetails =
        item['contentDetails'] as Map<String, dynamic>? ?? {};

    final title = (snippet['title'] ?? 'Untitled').toString();
    final artist = (snippet['channelTitle'] ?? 'Unknown artist').toString();
    final thumbnail =
        (snippet['thumbnails'] as Map<String, dynamic>?)?['high']
            as Map<String, dynamic>? ??
        {};
    final imageUrl = (thumbnail['url'] ?? '').toString();

    final durationStr = (contentDetails['duration'] ?? '').toString();
    final duration = _parseIso8601Duration(durationStr);

    return Song(
      id: videoId,
      title: title,
      artist: artist,
      album: 'YouTube',
      artworkUrl: imageUrl.isNotEmpty ? imageUrl : null,
      audioUrl: videoId,
      duration: duration,
    );
  }

  // 3. channels.list - Get channel details
  Future<Map<String, dynamic>?> getChannelDetails(String channelId) async {
    final url = Uri.parse(
      '${AppConstants.youtubeBaseUrl}/channels'
      '?part=snippet,statistics'
      '&id=$channelId'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      AudioLogger.logWarning(
        'YOUTUBE_API',
        'channels.list failed for $channelId: ${response.body}',
      );
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    if (items.isEmpty) return null;

    return items.first;
  }

  // 4. playlists.list - Get playlists for a channel or query
  Future<List<Playlist>> getPlaylists({
    String? channelId,
    String? query,
  }) async {
    final isPlaylistId = query != null && query.startsWith('PL');

    final url = Uri.parse(
      isPlaylistId
          ? '${AppConstants.youtubeBaseUrl}/playlists?part=snippet&id=$query&maxResults=10&key=$_apiKey'
          : '${AppConstants.youtubeBaseUrl}/search?part=snippet'
                '${channelId != null ? '&channelId=$channelId' : ''}'
                '${query != null ? '&q=${Uri.encodeComponent(query)}' : ''}'
                '&type=playlist&maxResults=10&key=$_apiKey',
    );

    AudioLogger.logInfo(
      'YOUTUBE_API',
      'getPlaylists request: ${isPlaylistId ? "ID=$query" : "query=$query, channel=$channelId"}',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      AudioLogger.logWarning(
        'YOUTUBE_API',
        'getPlaylists failed: ${response.statusCode} - ${response.body}',
      );
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];

    return items
        .map<Playlist>((item) {
          final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
          final rawId = item['id'];
          String playlistId = '';
          if (rawId is String) {
            playlistId = rawId;
          } else if (rawId is Map) {
            playlistId = (rawId['playlistId'] ?? '').toString();
          } else if (item.containsKey('id')) {
            playlistId = item['id'].toString();
          }

          final title = (snippet['title'] ?? 'Untitled').toString();
          final thumbnail =
              (snippet['thumbnails'] as Map<String, dynamic>?)?['high']
                  as Map<String, dynamic>? ??
              {};
          final imageUrl = (thumbnail['url'] ?? '').toString();

          return Playlist(
            id: playlistId.isNotEmpty
                ? playlistId
                : '${DateTime.now().millisecondsSinceEpoch}',
            name: title,
            coverUrl: imageUrl.isNotEmpty ? imageUrl : null,
            songs: const [],
          );
        })
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  // 5. playlistItems.list - Get songs inside a playlist
  Future<List<Song>> getPlaylistItems(String playlistId) async {
    final url = Uri.parse(
      '${AppConstants.youtubeBaseUrl}/playlistItems'
      '?part=snippet,contentDetails'
      '&playlistId=$playlistId'
      '&maxResults=50'
      '&key=$_apiKey',
    );

    AudioLogger.logInfo(
      'YOUTUBE_API',
      'Fetching playlist items for playlistId: $playlistId',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      AudioLogger.logWarning(
        'YOUTUBE_API',
        'playlistItems failed for $playlistId: ${response.statusCode} - ${response.body}',
      );
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];

    final songs = items
        .map<Song?>((item) {
          final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
          final contentDetails =
              item['contentDetails'] as Map<String, dynamic>? ?? {};
          final videoId = (contentDetails['videoId'] ?? '').toString();
          final title = (snippet['title'] ?? 'Untitled').toString();

          // Skip private or deleted videos
          if (title == 'Private video' ||
              title == 'Deleted video' ||
              videoId.isEmpty) {
            return null;
          }

          final artist = (snippet['videoOwnerChannelTitle'] ?? 'Unknown artist')
              .toString();
          final thumbnail =
              (snippet['thumbnails'] as Map<String, dynamic>?)?['high']
                  as Map<String, dynamic>? ??
              {};
          final imageUrl = (thumbnail['url'] ?? '').toString();

          return Song(
            id: videoId,
            title: title,
            artist: artist,
            album: 'YouTube Playlist',
            artworkUrl: imageUrl.isNotEmpty ? imageUrl : null,
            audioUrl: videoId,
            duration: Duration.zero,
          );
        })
        .whereType<Song>()
        .toList();

    AudioLogger.logPlaylistEvent(
      event: 'LOADED_PLAYLIST_ITEMS',
      playlistId: playlistId,
      songCount: songs.length,
    );

    return _hydrateDurations(songs);
  }

  Future<List<Song>> _hydrateDurations(List<Song> songs) async {
    final ids = songs.map((s) => s.id).where((id) => id.length == 11).toList();
    if (ids.isEmpty) return songs;

    final durations = <String, Duration>{};
    for (var i = 0; i < ids.length; i += 50) {
      final chunk = ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50);
      final url = Uri.parse(
        '${AppConstants.youtubeBaseUrl}/videos'
        '?part=contentDetails'
        '&id=${chunk.join(',')}'
        '&key=$_apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) continue;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        final id = (map['id'] ?? '').toString();
        final contentDetails =
            map['contentDetails'] as Map<String, dynamic>? ?? {};
        durations[id] = _parseIso8601Duration(
          (contentDetails['duration'] ?? '').toString(),
        );
      }
    }

    return songs
        .map(
          (song) => durations.containsKey(song.id)
              ? song.copyWith(duration: durations[song.id])
              : song,
        )
        .toList();
  }

  Duration _parseIso8601Duration(String isoDuration) {
    if (isoDuration.isEmpty) return Duration.zero;
    final regex = RegExp(
      r'^P(?:(\d+)D)?T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$',
    );
    final match = regex.firstMatch(isoDuration);
    if (match == null) return Duration.zero;

    final days = int.tryParse(match.group(1) ?? '') ?? 0;
    final hours = int.tryParse(match.group(2) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(3) ?? '') ?? 0;
    final seconds = double.tryParse(match.group(4) ?? '') ?? 0;

    return Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      milliseconds: (seconds * 1000).round(),
    );
  }
}
