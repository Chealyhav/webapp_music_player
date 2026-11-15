import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:samnieng_music/core/utils/audio_logger.dart';
import 'package:samnieng_music/data/datasources/local/music_local_datasource.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/data/repositories/music_repository.dart';
import 'package:samnieng_music/data/datasources/remote/youtube_datasource.dart';
import 'package:samnieng_music/features/home/state/home_state.dart';
import 'package:samnieng_music/services/audio/audio_player_service.dart';
import 'package:samnieng_music/services/storage/preferences_service.dart';

final youtubeDatasourceProvider = Provider<YoutubeDatasource>((ref) {
  final datasource = YoutubeDatasource();
  ref.onDispose(() => datasource.dispose());
  return datasource;
});

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepository(
    localDatasource: MusicLocalDatasource(),
    youtubeDatasource: ref.watch(youtubeDatasourceProvider),
  );
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final ytDatasource = ref.watch(youtubeDatasourceProvider);
  final service = AudioPlayerService(youtubeDatasource: ytDatasource);
  ref.onDispose(() => service.dispose());
  return service;
});

final currentSongProvider = StateProvider<Song?>((ref) => null);
final playbackQueueProvider = StateProvider<List<Song>>((ref) => <Song>[]);
final queueIndexProvider = StateProvider<int>((ref) => 0);
final shuffleEnabledProvider = StateProvider<bool>((ref) => false);
final repeatEnabledProvider = StateProvider<bool>((ref) => false);
final playbackErrorProvider = StateProvider<TrackErrorDetails?>((ref) => null);
final volumeProvider = StateProvider<double>((ref) => 1.0);

final isPlayingProvider = StreamProvider<bool>((ref) {
  final audioService = ref.watch(audioPlayerServiceProvider);
  return audioService.playerStateStream;
});

final positionProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioPlayerServiceProvider);
  return audioService.positionStream;
});

final durationProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioPlayerServiceProvider);
  return audioService.durationStream.map((dur) => dur ?? Duration.zero);
});

// Auto advance queue when current song completes
final autoAdvanceProvider = Provider<void>((ref) {
  final audioService = ref.watch(audioPlayerServiceProvider);
  final subscription = audioService.processingStateStream.listen((state) {
    if (state == ProcessingState.completed) {
      AudioLogger.logPlaylistEvent(
        event: 'TRACK_COMPLETED',
        playlistId: 'queue',
        extra: 'Song reached completion. Passing playlist to next track.',
      );
      playQueueOffset(ref, 1, isAutoAdvance: true);
    }
  });

  final errorSubscription = audioService.playbackErrorStream.listen((error) {
    ref.read(playbackErrorProvider.notifier).state = error;
  });

  ref.onDispose(() {
    subscription.cancel();
    errorSubscription.cancel();
  });
});

Future<void> startPlayback(dynamic ref, Song song, {List<Song>? queue}) async {
  final List<Song> list = List<Song>.from(
    queue ?? ref.read(playbackQueueProvider),
  );

  if (list.isEmpty || !list.any((s) => s.id == song.id)) {
    list
      ..clear()
      ..add(song);
  }

  int index = list.indexWhere((s) => s.id == song.id);
  if (index < 0) {
    list.insert(0, song);
    index = 0;
  }

  ref.read(playbackQueueProvider.notifier).state = list;
  ref.read(queueIndexProvider.notifier).state = index;
  ref.read(currentSongProvider.notifier).state = song;
  ref.read(recentlyPlayedProvider.notifier).addSong(song);
  ref.read(playbackErrorProvider.notifier).state = null;

  PreferencesService.instance.saveLastSong(song);

  AudioLogger.logPlaylistEvent(
    event: 'START_PLAYBACK',
    playlistId: 'queue',
    playlistName: 'Queue',
    songCount: list.length,
    song: song,
    extra: 'Queue index: $index / ${list.length}',
  );

  final success = await ref.read(audioPlayerServiceProvider).playSong(song);
  if (!success) {
    final lastErr = ref.read(audioPlayerServiceProvider).lastError;
    ref.read(playbackErrorProvider.notifier).state = lastErr;
    AudioLogger.logPlaylistEvent(
      event: 'PLAYBACK_FAILED_STOPPED',
      playlistId: 'queue',
      song: song,
      extra: 'Playback failed. Queue remains on this track and playback is stopped.',
    );
  }
}

void playNext(dynamic ref, Song song) {
  final List<Song> queue = List<Song>.from(ref.read(playbackQueueProvider));
  final int currentIndex = ref.read(queueIndexProvider);

  if (queue.isEmpty) {
    startPlayback(ref, song);
    return;
  }

  // Insert right after current track
  final insertIndex = currentIndex + 1;
  queue.insert(insertIndex, song);
  ref.read(playbackQueueProvider.notifier).state = queue;

  AudioLogger.logPlaylistEvent(
    event: 'PLAY_NEXT_ADDED',
    playlistId: 'queue',
    songCount: queue.length,
    song: song,
    extra: 'Inserted at index $insertIndex in queue',
  );
}

void addToPlaybackQueue(dynamic ref, Song song) {
  final List<Song> queue = List<Song>.from(ref.read(playbackQueueProvider));
  if (queue.isEmpty) {
    startPlayback(ref, song);
    return;
  }
  queue.add(song);
  ref.read(playbackQueueProvider.notifier).state = queue;

  AudioLogger.logPlaylistEvent(
    event: 'ADD_TO_QUEUE',
    playlistId: 'queue',
    songCount: queue.length,
    song: song,
  );
}

void playQueueOffset(dynamic ref, int delta, {bool isAutoAdvance = false}) {
  final List<Song> queue = List<Song>.from(ref.read(playbackQueueProvider));
  if (queue.isEmpty) return;

  final bool repeat = ref.read(repeatEnabledProvider);
  final bool shuffle = ref.read(shuffleEnabledProvider);
  final int currentIndex = ref.read(queueIndexProvider);
  final int queueLength = queue.length;

  int index;
  if (shuffle && queueLength > 1) {
    index = Random().nextInt(queueLength);
    if (index == currentIndex) {
      index = (index + 1) % queueLength;
    }
  } else {
    index = currentIndex + delta;
    if (index < 0 || index >= queueLength) {
      if (!repeat && isAutoAdvance && delta > 0) {
        AudioLogger.logPlaylistEvent(
          event: 'QUEUE_REACHED_END',
          playlistId: 'queue',
          extra:
              'End of playlist reached with repeat off. Stopping auto-advance.',
        );
        return;
      }
      index = ((index % queueLength) + queueLength) % queueLength;
    }
  }

  AudioLogger.logPlaylistEvent(
    event: 'QUEUE_OFFSET_NAVIGATION',
    playlistId: 'queue',
    songCount: queueLength,
    extra: 'Moving queue index from $currentIndex to $index (delta: $delta)',
  );

  startPlayback(ref, queue[index], queue: queue);
}
