import '../datasources/local/music_local_datasource.dart';
import '../datasources/remote/youtube_datasource.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class MusicRepository {
  final MusicLocalDatasource localDatasource;
  final YoutubeDatasource youtubeDatasource;

  MusicRepository({
    required this.localDatasource,
    required this.youtubeDatasource,
  });

  // Local Database
  Future<List<Song>> fetchLocalSongs() async {
    return await localDatasource.getLocalSongs();
  }

  // YouTube API
  Future<List<Song>> searchSongs(String query) async {
    return await youtubeDatasource.searchYoutube(query);
  }

  Future<Song?> getVideoDetails(String videoId) async {
    return await youtubeDatasource.getVideoDetails(videoId);
  }

  Future<List<Playlist>> getPlaylists({String? channelId, String? query}) async {
    return await youtubeDatasource.getPlaylists(channelId: channelId, query: query);
  }

  Future<List<Song>> getPlaylistItems(String playlistId) async {
    return await youtubeDatasource.getPlaylistItems(playlistId);
  }

  Future<Map<String, dynamic>?> getChannelDetails(String channelId) async {
    return await youtubeDatasource.getChannelDetails(channelId);
  }

  Future<String?> getAudioStreamUrl(String videoIdOrUrl) async {
    return await youtubeDatasource.getAudioStreamUrl(videoIdOrUrl);
  }
}
