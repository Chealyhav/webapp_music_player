import 'package:flutter/material.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/music/widgets/song_card.dart';

class SearchResultWidget extends StatelessWidget {
  final List<Song> results;
  final Function(Song) onSelectSong;

  const SearchResultWidget({
    super.key,
    required this.results,
    required this.onSelectSong,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return SongCard(
          song: results[index],
          onTap: () => onSelectSong(results[index]),
        );
      },
    );
  }
}
