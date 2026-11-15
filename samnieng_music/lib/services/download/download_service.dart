import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models/song.dart';
import '../storage/downloaded_song_db.dart';
import '../storage/library_store.dart';
import 'download_bytes.dart';

final downloadServiceProvider = Provider((ref) => DownloadService());

class DownloadService {
  final _yt = YoutubeExplode();

  Future<Song> downloadSong(Song song) async {
    final videoId = _videoIdOf(song);
    if (videoId == null) {
      throw Exception('This track has no YouTube id to convert.');
    }

    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final streamInfo = _smallestAudio(manifest.audioOnly);
    if (streamInfo == null) {
      throw Exception('No audio stream available for this video.');
    }

    final extension = _audioExtension(streamInfo.container.name);
    final safeTitle = _safeFileName(song.title);
    final fileName = '$safeTitle.$extension';
    final bytes = await _collectBytes(_yt.videos.streamsClient.get(streamInfo));

    String audioUrl = song.audioUrl;
    if (kIsWeb) {
      saveBytes(Uint8List.fromList(bytes), fileName);
      audioUrl = fileName;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = p.join(dir.path, 'downloads', fileName);
      final file = File(savePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      audioUrl = savePath;
    }

    final saved = song.copyWith(audioUrl: audioUrl, isOffline: true);
    await DownloadedSongDatabase.instance.saveSong(saved);

    final downloads = await LibraryStore.instance.loadDownloads();
    final next = [saved, ...downloads.where((s) => s.id != saved.id)];
    await LibraryStore.instance.saveDownloads(next);
    return saved;
  }

  AudioOnlyStreamInfo? _smallestAudio(Iterable<AudioOnlyStreamInfo> audioOnly) {
    final sorted = audioOnly.toList()
      ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
    if (sorted.isEmpty) return null;

    final compactMp4 = sorted.where((s) {
      final name = s.container.name.toLowerCase();
      return (name.contains('mp4') || name.contains('m4a')) &&
          s.bitrate.bitsPerSecond <= 96000;
    });
    if (compactMp4.isNotEmpty) return compactMp4.first;

    final mp4 = sorted.where((s) {
      final name = s.container.name.toLowerCase();
      return name.contains('mp4') || name.contains('m4a');
    });
    if (mp4.isNotEmpty) return mp4.first;
    return sorted.first;
  }

  String _audioExtension(String container) {
    final name = container.toLowerCase();
    if (name.contains('webm')) return 'webm';
    if (name.contains('mp3')) return 'mp3';
    return 'm4a';
  }

  String? _videoIdOf(Song song) {
    final candidates = [song.id, song.audioUrl];
    for (final value in candidates) {
      final trimmed = value.trim();
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters['v'] != null) {
        return uri.queryParameters['v'];
      }
      if (uri != null && uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }
    return null;
  }

  String _safeFileName(String title) {
    final cleaned = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleaned.isEmpty) return 'samnieng_audio';
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  Future<List<int>> _collectBytes(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return chunks;
  }

  void dispose() {
    _yt.close();
  }
}
