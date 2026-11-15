import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/core/widgets/app_loading.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';
import 'package:samnieng_music/features/home/state/home_state.dart';
import 'package:samnieng_music/features/home/widgets/youtube_music_section.dart';
import 'package:samnieng_music/features/home/widgets/recently_played.dart';
import 'package:samnieng_music/features/home/widgets/popular_songs.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(homeGreetingProvider);
    final musicRepo = ref.watch(musicRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with logo + search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Samnieng Music',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists, albums, or YouTube...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ),
              ),
            ),

            // Greeting Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.bannerGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Discover new music today',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
            ),

            // YouTube Music Section
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: FutureBuilder(
                future: musicRepo.searchSongs('Top Trending Music 2024'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 170, child: Center(child: CircularProgressIndicator()));
                  }
                  final songs = snapshot.data ?? [];
                  return YoutubeMusicSection(
                    songs: songs,
                    onSongTap: (song) {
                      startPlayback(ref, song, queue: songs);
                    },
                  );
                },
              ),
            ),

            // Recently Played
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: FutureBuilder(
                future: musicRepo.fetchLocalSongs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 170,
                      child: AppLoading(message: 'Loading recently played...'),
                    );
                  }
                  final songs = snapshot.data ?? [];
                  return RecentlyPlayed(
                    songs: songs,
                    onSongTap: (song) {
                      startPlayback(ref, song, queue: songs);
                    },
                  );
                },
              ),
            ),

            // Popular Songs
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: FutureBuilder(
                future: musicRepo.searchSongs('Popular Khmer Music'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
                  }
                  final songs = snapshot.data ?? [];
                  return PopularSongs(
                    songs: songs,
                    onSongTap: (song) {
                      startPlayback(ref, song, queue: songs);
                    },
                  );
                },
              ),
            ),

            // Bottom padding for mini player
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
