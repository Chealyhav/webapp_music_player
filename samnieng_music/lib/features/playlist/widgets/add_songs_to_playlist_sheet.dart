import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/data/models/playlist.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/home/state/home_state.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';
import 'package:samnieng_music/features/playlist/state/playlist_state.dart';

void showAddSongsToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  Playlist playlist,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddSongsToPlaylistSheet(playlistId: playlist.id),
  );
}

class AddSongsToPlaylistSheet extends ConsumerStatefulWidget {
  final String playlistId;

  const AddSongsToPlaylistSheet({super.key, required this.playlistId});

  @override
  ConsumerState<AddSongsToPlaylistSheet> createState() =>
      _AddSongsToPlaylistSheetState();
}

class _AddSongsToPlaylistSheetState
    extends ConsumerState<AddSongsToPlaylistSheet> {
  final _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(musicRepositoryProvider);
      final results = await repo.searchSongs(trimmed);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final playlist = playlists.firstWhere(
      (p) => p.id == widget.playlistId,
      orElse: () => Playlist(id: widget.playlistId, name: 'Playlist'),
    );

    final recentSongs = ref.watch(recentlyPlayedProvider);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Songs',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'To "${playlist.name}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Box
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search YouTube or local songs...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: _performSearch,
              ),
            ),
            const SizedBox(height: 12),

            // List of songs
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _searchResults.isNotEmpty
                      ? ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final song = _searchResults[index];
                            final isAdded = playlist.songs.any((s) => s.id == song.id);

                            return _buildSongItem(song, isAdded, playlist);
                          },
                        )
                      : recentSongs.isNotEmpty
                          ? ListView(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Recent & Suggested Songs',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ...recentSongs.map((song) {
                                  final isAdded = playlist.songs.any((s) => s.id == song.id);
                                  return _buildSongItem(song, isAdded, playlist);
                                }),
                              ],
                            )
                          : const Center(
                              child: Text(
                                'Search songs to add to this playlist',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(Song song, bool isAdded, Playlist playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isAdded
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            color: AppColors.surfaceVariant,
            child: song.artworkUrl != null
                ? Image.network(
                    song.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.music_note,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                    size: 22,
                  ),
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isAdded ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(
            isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
            color: isAdded ? AppColors.primary : AppColors.textSecondary,
            size: 26,
          ),
          onPressed: () async {
            if (isAdded) {
              await ref
                  .read(playlistsProvider.notifier)
                  .removeSong(playlist.id, song.id);
            } else {
              await ref
                  .read(playlistsProvider.notifier)
                  .addSong(playlist.id, song);
            }
          },
        ),
      ),
    );
  }
}
