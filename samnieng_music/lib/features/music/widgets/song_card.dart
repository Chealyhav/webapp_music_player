import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/favorites/state/favorites_state.dart';
import 'package:samnieng_music/features/music/state/library_state.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';
import 'package:samnieng_music/features/playlist/widgets/add_to_playlist_sheet.dart';
import 'package:samnieng_music/services/download/download_service.dart';
import 'package:samnieng_music/services/storage/downloaded_song_db.dart';

class SongCard extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;
  final bool showDuration;

  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.showDuration = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: AppColors.surfaceLight,
                    child: song.artworkUrl != null
                        ? Image.network(
                            song.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.music_note,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          )
                        : const Icon(Icons.music_note, color: AppColors.primary, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDuration)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _formatDuration(song.duration),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                // More options (Add to playlist, play next, favorite)
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => _showSongOptions(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, WidgetRef ref) {
    final isFav = ref.read(favoritesProvider.notifier).isFavorite(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: AppColors.surfaceVariant,
                      child: song.artworkUrl != null
                          ? Image.network(song.artworkUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.music_note, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.surfaceVariant, height: 1),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: AppColors.primary),
                title: const Text('Add to Playlist', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddToPlaylistSheet(context, ref, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_play_next_rounded, color: AppColors.secondary),
                title: const Text('Play Next', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  playNext(ref, song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing "${song.title}" next'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_to_queue_rounded, color: AppColors.textSecondary),
                title: const Text('Add to Queue', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  addToPlaybackQueue(ref, song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${song.title}" to queue'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.accent : AppColors.textPrimary,
                ),
                title: Text(
                  isFav ? 'Remove from Favorites' : 'Add to Favorites',
                  style: TextStyle(color: isFav ? AppColors.accent : AppColors.textPrimary),
                ),
                onTap: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(song);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: AppColors.primary),
                title: const Text('Download Song', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () async {
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _downloadSong(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Future<void> _downloadSong(BuildContext context, WidgetRef ref) async {
    // Skip if already downloaded
    if (await DownloadedSongDatabase.instance.hasSong(song.id)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${song.title}" is already downloaded'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Show download progress dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Downloading'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Downloading "${song.title}"...',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );

    try {
      final downloadService = ref.read(downloadServiceProvider);
      final downloaded = await downloadService.downloadSong(song);

      // Persist to SQLite with the actual file path
      await DownloadedSongDatabase.instance.saveSong(
        downloaded,
        filePath: downloaded.audioUrl,
      );

      // Refresh downloads list so the Downloaded tab updates
      ref.read(downloadsRefreshProvider.notifier).state++;

      if (context.mounted) Navigator.of(context).pop(); // close dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${song.title}" downloaded successfully'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // close dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
