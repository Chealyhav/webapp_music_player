import '../../data/models/song.dart';
import 'app_database.dart';

class DownloadedSongDatabase {
  DownloadedSongDatabase._();

  static final DownloadedSongDatabase instance = DownloadedSongDatabase._();

  Future<void> saveSong(Song song, {String? filePath}) async {
    final downloadedSong = song.copyWith(isOffline: true);
    await AppDatabase.instance.saveSong(downloadedSong, filePath: filePath);
  }

  Future<List<Song>> getSongs() async {
    return AppDatabase.instance.getSongs();
  }

  Future<Song?> getSong(String id) async {
    return AppDatabase.instance.getSong(id);
  }

  Future<bool> hasSong(String id) async {
    return AppDatabase.instance.hasSong(id);
  }

  Future<void> deleteSong(String id) async {
    await AppDatabase.instance.deleteSong(id);
  }
}
