import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/playlist.dart';
import '../../data/models/song.dart';

class LibraryStore {
  LibraryStore._();
  static final LibraryStore instance = LibraryStore._();

  static const _favoritesKey = 'library_favorites';
  static const _playlistsKey = 'library_playlists';
  static const _recentKey = 'library_recent';
  static const _downloadsKey = 'library_downloads';

  Future<List<Song>> loadFavorites() => _loadSongs(_favoritesKey);
  Future<void> saveFavorites(List<Song> songs) => _saveSongs(_favoritesKey, songs);

  Future<List<Song>> loadRecent() => _loadSongs(_recentKey);
  Future<void> saveRecent(List<Song> songs) => _saveSongs(_recentKey, songs);

  Future<List<Song>> loadDownloads() => _loadSongs(_downloadsKey);
  Future<void> saveDownloads(List<Song> songs) => _saveSongs(_downloadsKey, songs);

  Future<List<Playlist>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playlistsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Playlist.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playlistsKey,
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<Song>> _loadSongs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Song.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveSongs(String key, List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(songs.map((s) => s.toJson()).toList()),
    );
  }
}
