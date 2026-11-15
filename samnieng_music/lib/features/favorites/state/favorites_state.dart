import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/song.dart';
import '../../../services/storage/library_store.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Song>>((
  ref,
) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Song>> {
  FavoritesNotifier() : super([]) {
    _load();
  }

  bool isFavorite(String id) => state.any((s) => s.id == id);

  Future<void> _load() async {
    state = await LibraryStore.instance.loadFavorites();
  }

  Future<void> toggleFavorite(Song song) async {
    if (state.any((s) => s.id == song.id)) {
      state = state.where((s) => s.id != song.id).toList();
    } else {
      state = [...state, song.copyWith(isFavorite: true)];
    }
    await LibraryStore.instance.saveFavorites(state);
  }
}
