import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/song.dart';
import '../../../services/storage/library_store.dart';

final recentlyPlayedProvider =
    StateNotifierProvider<RecentlyPlayedNotifier, List<Song>>((ref) {
  return RecentlyPlayedNotifier();
});

final homeGreetingProvider = Provider<String>((ref) {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
});

class RecentlyPlayedNotifier extends StateNotifier<List<Song>> {
  RecentlyPlayedNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await LibraryStore.instance.loadRecent();
  }

  Future<void> addSong(Song song) async {
    state = [song, ...state.where((s) => s.id != song.id)].take(50).toList();
    await LibraryStore.instance.saveRecent(state);
  }
}
