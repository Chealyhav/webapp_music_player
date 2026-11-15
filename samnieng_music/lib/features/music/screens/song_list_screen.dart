import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/core/utils/format_utils.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';
import 'package:samnieng_music/features/music/widgets/song_card.dart';

class SongListScreen extends ConsumerWidget {
  final String title;
  final List<Song> songs;

  const SongListScreen({
    super.key,
    required this.title,
    required this.songs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
      ),
      body: songs.isEmpty
          ? const Center(
              child: Text(
                'No songs yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongCard(
                  song: song,
                  showDuration: true,
                  onTap: () => startPlayback(ref, song, queue: songs),
                );
              },
            ),
    );
  }
}

String songListSubtitle(Song song) {
  final duration = FormatUtils.formatDuration(song.duration);
  return song.duration == Duration.zero ? song.artist : '${song.artist} · $duration';
}
