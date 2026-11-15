import '../datasources/remote/youtube_datasource.dart';
import '../models/song.dart';

class YoutubeRepository {
  final YoutubeDatasource youtubeDatasource;

  YoutubeRepository({required this.youtubeDatasource});

  Future<List<Song>> search(String query) async {
    return await youtubeDatasource.searchYoutube(query);
  }
}
