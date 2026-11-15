import '../../models/song.dart';
import 'database_helper.dart';

class MusicLocalDatasource {
  Future<List<Song>> getLocalSongs() async {
    return await DatabaseHelper.instance.getAllSongs();
  }
}
