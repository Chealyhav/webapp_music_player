import 'package:flutter/material.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/music/widgets/song_card.dart';

class PopularSongs extends StatelessWidget {
  final List<Song> songs;
  final Function(Song) onSongTap;

  const PopularSongs({
    super.key,
    required this.songs,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Songs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return SongCard(
              song: songs[index],
              onTap: () => onSongTap(songs[index]),
            );
          },
        ),
      ],
    );
  }
}
