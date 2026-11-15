import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/utils/audio_logger.dart';
import 'package:samnieng_music/data/models/playlist.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/services/storage/library_store.dart';

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, List<Playlist>>((ref) {
  return PlaylistsNotifier();
});

class PlaylistsNotifier extends StateNotifier<List<Playlist>> {
  PlaylistsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await LibraryStore.instance.loadPlaylists();
    AudioLogger.logPlaylistEvent(
      event: 'PLAYLISTS_LOADED',
      playlistId: 'all',
      songCount: state.fold<int>(0, (sum, p) => sum + p.songCount),
      extra: 'Loaded ${state.length} playlists from local storage',
    );
  }

  Future<void> _save() => LibraryStore.instance.savePlaylists(state);

  Future<Playlist> createPlaylist(String name) async {
    final cleanName = name.trim().isEmpty ? 'My Playlist' : name.trim();
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      songs: const [],
    );
    state = [playlist, ...state];
    await _save();

    AudioLogger.logPlaylistEvent(
      event: 'CREATE_PLAYLIST',
      playlistId: playlist.id,
      playlistName: playlist.name,
      songCount: 0,
    );
    return playlist;
  }

  Future<bool> addSong(String playlistId, Song song) async {
    bool alreadyExists = false;
    state = state.map((playlist) {
      if (playlist.id != playlistId) return playlist;
      if (playlist.songs.any((s) => s.id == song.id)) {
        alreadyExists = true;
        return playlist;
      }
      final updatedSongs = [...playlist.songs, song];
      return playlist.copyWith(
        songs: updatedSongs,
        coverUrl: playlist.coverUrl ?? song.artworkUrl,
      );
    }).toList();

    if (!alreadyExists) {
      await _save();
      final target = state.firstWhere((p) => p.id == playlistId, orElse: () => Playlist(id: playlistId, name: ''));
      AudioLogger.logPlaylistEvent(
        event: 'ADD_SONG_TO_PLAYLIST',
        playlistId: playlistId,
        playlistName: target.name,
        songCount: target.songCount,
        song: song,
      );
      return true;
    }
    return false;
  }

  Future<void> removeSong(String playlistId, String songId) async {
    Song? removedSong;
    state = state.map((playlist) {
      if (playlist.id != playlistId) return playlist;
      final match = playlist.songs.where((s) => s.id == songId);
      if (match.isNotEmpty) {
        removedSong = match.first;
      }
      final updatedSongs = playlist.songs.where((s) => s.id != songId).toList();
      return playlist.copyWith(
        songs: updatedSongs,
        coverUrl: updatedSongs.isNotEmpty
            ? (playlist.coverUrl ?? updatedSongs.first.artworkUrl)
            : null,
      );
    }).toList();

    await _save();
    AudioLogger.logPlaylistEvent(
      event: 'REMOVE_SONG_FROM_PLAYLIST',
      playlistId: playlistId,
      song: removedSong,
      extra: 'Song ID $songId removed',
    );
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    state = state.map((playlist) {
      if (playlist.id != playlistId) return playlist;
      return playlist.copyWith(name: cleanName);
    }).toList();

    await _save();
    AudioLogger.logPlaylistEvent(
      event: 'RENAME_PLAYLIST',
      playlistId: playlistId,
      playlistName: cleanName,
    );
  }

  Future<void> clearPlaylist(String playlistId) async {
    state = state.map((playlist) {
      if (playlist.id != playlistId) return playlist;
      return playlist.copyWith(songs: []);
    }).toList();

    await _save();
    AudioLogger.logPlaylistEvent(
      event: 'CLEAR_PLAYLIST',
      playlistId: playlistId,
      extra: 'All songs cleared',
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    final target = state.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => Playlist(id: playlistId, name: 'Deleted'),
    );
    state = state.where((p) => p.id != playlistId).toList();
    await _save();

    AudioLogger.logPlaylistEvent(
      event: 'DELETE_PLAYLIST',
      playlistId: playlistId,
      playlistName: target.name,
      songCount: target.songCount,
    );
  }

  bool isSongInPlaylist(String playlistId, String songId) {
    final playlist = state.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => const Playlist(id: '', name: ''),
    );
    return playlist.songs.any((s) => s.id == songId);
  }
}
