import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/song.dart';

class PreferencesService {
  static const String _keyLastSong = 'last_played_song';

  static final PreferencesService instance = PreferencesService._internal();
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveLastSong(Song song) async {
    if (_prefs == null) await init();
    
    // We need to implement toJson/fromJson on Song if it doesn't exist.
    // Assuming Song has a fromJson factory and toJson method.
    try {
      final jsonString = jsonEncode(song.toJson());
      await _prefs!.setString(_keyLastSong, jsonString);
    } catch (e) {
      print('Error saving last song: $e');
    }
  }

  Future<Song?> getLastSong() async {
    if (_prefs == null) await init();
    final jsonString = _prefs!.getString(_keyLastSong);
    if (jsonString != null) {
      try {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return Song.fromJson(map);
      } catch (e) {
        print('Error loading last song from preferences: $e');
      }
    }
    return null;
  }
}
