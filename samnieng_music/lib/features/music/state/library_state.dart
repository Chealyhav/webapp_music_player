import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/services/storage/downloaded_song_db.dart';

final downloadsRefreshProvider = StateProvider<int>((ref) => 0);

final downloadedSongsProvider = FutureProvider<List<Song>>((ref) async {
  ref.watch(downloadsRefreshProvider);
  return DownloadedSongDatabase.instance.getSongs();
});
