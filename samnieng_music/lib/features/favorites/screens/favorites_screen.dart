import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';
import 'package:samnieng_music/features/music/widgets/song_card.dart';
import '../state/favorites_state.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Pinned header
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.surfaceLight, AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            title: const Text(
              'Liked Songs',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (favorites.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    final shuffled = List<Song>.from(favorites)..shuffle();
                    startPlayback(ref, shuffled.first, queue: shuffled);
                  },
                ),
            ],
          ),

          // Song count header
          if (favorites.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${favorites.length} liked songs',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => startPlayback(ref, favorites.first, queue: favorites),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // List
          if (favorites.isEmpty)
            const SliverFillRemaining(child: _FavEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = favorites[index];
                    return Dismissible(
                      key: Key(song.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(favoritesProvider.notifier).toggleFavorite(song);
                      },
                      child: SongCard(
                        song: song,
                        onTap: () => startPlayback(ref, song, queue: favorites),
                        showDuration: true,
                      ),
                    );
                  },
                  childCount: favorites.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FavEmptyState extends StatelessWidget {
  const _FavEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.favorite_border_rounded, color: AppColors.accent, size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Liked Songs Yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Songs you like will appear here.\nTap ♥ on any song to save it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
