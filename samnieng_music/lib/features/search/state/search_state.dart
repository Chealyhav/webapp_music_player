import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/data/datasources/remote/youtube_datasource.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/data/repositories/youtube_repository.dart';

final youtubeRepoProvider = Provider<YoutubeRepository>((ref) {
  return YoutubeRepository(youtubeDatasource: YoutubeDatasource());
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final repo = ref.watch(youtubeRepoProvider);
  return await repo.search(query);
});
