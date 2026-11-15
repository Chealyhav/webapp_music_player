import '../../models/playlist.dart';
import 'database_helper.dart';

class PlaylistLocalDatasource {
  Future<List<Playlist>> getPlaylists() async {
    return await DatabaseHelper.instance.getAllPlaylists();
  }
}
