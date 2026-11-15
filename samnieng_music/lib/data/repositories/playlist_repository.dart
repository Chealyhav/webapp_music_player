import '../datasources/local/playlist_local_datasource.dart';
import '../models/playlist.dart';

class PlaylistRepository {
  final PlaylistLocalDatasource localDatasource;

  PlaylistRepository({required this.localDatasource});

  Future<List<Playlist>> fetchPlaylists() async {
    return await localDatasource.getPlaylists();
  }
}
