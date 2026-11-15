import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/data/models/playlist.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';
import 'package:samnieng_music/features/music/widgets/song_card.dart';
import 'package:samnieng_music/features/playlist/state/playlist_state.dart';
import 'package:samnieng_music/features/playlist/widgets/add_songs_to_playlist_sheet.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically watch the playlist from playlistsProvider to reflect real-time updates
    final allPlaylists = ref.watch(playlistsProvider);
    final currentPlaylist = allPlaylists.firstWhere(
      (p) => p.id == playlist.id,
      orElse: () => playlist,
    );

    final songs = currentPlaylist.songs;
    final totalDuration =
        songs.fold(Duration.zero, (sum, s) => sum + s.duration);
    final coverUrl = currentPlaylist.coverUrl ??
        (songs.isNotEmpty ? songs.first.artworkUrl : null);

    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final isPlaylistActive =
        currentSong != null && songs.any((s) => s.id == currentSong.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsing header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                tooltip: 'Add songs',
                onPressed: () => showAddSongsToPlaylistSheet(
                  context,
                  ref,
                  currentPlaylist,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => _showOptions(context, ref, currentPlaylist),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background artwork blur
                  if (coverUrl != null)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.5),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, _, _) =>
                          Container(color: AppColors.surfaceLight),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.surfaceLight,
                            AppColors.background,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Cover + info
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cover thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: AppColors.surfaceLight,
                            child: coverUrl != null
                                ? Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.queue_music_rounded,
                                      color: AppColors.primary,
                                      size: 48,
                                    ),
                                  )
                                : const Icon(
                                    Icons.queue_music_rounded,
                                    color: AppColors.primary,
                                    size: 48,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentPlaylist.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${songs.length} songs · ${_formatDuration(totalDuration)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play/Shuffle action row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _PlayButton(
                      label: (isPlaylistActive && isPlaying)
                          ? 'Pause'
                          : (isPlaylistActive ? 'Resume' : 'Play All'),
                      icon: (isPlaylistActive && isPlaying)
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onTap: songs.isEmpty
                          ? null
                          : () {
                              if (isPlaylistActive) {
                                final audioService =
                                    ref.read(audioPlayerServiceProvider);
                                if (isPlaying) {
                                  audioService.pause();
                                } else {
                                  audioService.resume();
                                }
                              } else {
                                ref
                                    .read(shuffleEnabledProvider.notifier)
                                    .state = false;
                                startPlayback(ref, songs.first, queue: songs);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlayButton(
                      label: 'Shuffle',
                      icon: Icons.shuffle_rounded,
                      outlined: true,
                      onTap: songs.isEmpty
                          ? null
                          : () {
                              ref
                                  .read(shuffleEnabledProvider.notifier)
                                  .state = true;
                              final shuffled = List<Song>.from(songs)..shuffle();
                              startPlayback(
                                ref,
                                shuffled.first,
                                queue: shuffled,
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Song list or empty state
          songs.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No songs yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Search songs and add them to this playlist',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => showAddSongsToPlaylistSheet(
                            context,
                            ref,
                            currentPlaylist,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Songs'),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = songs[index];
                        return Dismissible(
                          key: Key('${currentPlaylist.id}_${song.id}'),
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
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          onDismissed: (_) {
                            ref
                                .read(playlistsProvider.notifier)
                                .removeSong(currentPlaylist.id, song.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Removed "${song.title}" from playlist',
                                ),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    ref
                                        .read(playlistsProvider.notifier)
                                        .addSong(currentPlaylist.id, song);
                                  },
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          child: SongCard(
                            song: song,
                            onTap: () =>
                                startPlayback(ref, song, queue: songs),
                            showDuration: true,
                          ),
                        );
                      },
                      childCount: songs.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    WidgetRef ref,
    Playlist currentPlaylist,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlaylistOptionsSheet(
        playlist: currentPlaylist,
        widgetRef: ref,
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours} hr ${d.inMinutes.remainder(60)} min';
    }
    return '${d.inMinutes} min';
  }
}

class _PlayButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;

  const _PlayButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: outlined ? null : AppColors.primaryGradient,
          border: outlined
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: outlined ? AppColors.primary : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: outlined ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistOptionsSheet extends StatelessWidget {
  final Playlist playlist;
  final WidgetRef widgetRef;

  const _PlaylistOptionsSheet({
    required this.playlist,
    required this.widgetRef,
  });

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename Playlist',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter new playlist name',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                widgetRef
                    .read(playlistsProvider.notifier)
                    .renamePlaylist(playlist.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            const SizedBox(height: 16),
            Text(
              playlist.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.add_rounded,
              label: 'Add Songs',
              onTap: () {
                Navigator.pop(context);
                showAddSongsToPlaylistSheet(context, widgetRef, playlist);
              },
            ),
            _OptionTile(
              icon: Icons.edit_rounded,
              label: 'Rename Playlist',
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            _OptionTile(
              icon: Icons.clear_all_rounded,
              label: 'Clear All Songs',
              onTap: () {
                Navigator.pop(context);
                widgetRef
                    .read(playlistsProvider.notifier)
                    .clearPlaylist(playlist.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cleared all songs from playlist'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Playlist',
              color: AppColors.error,
              onTap: () {
                widgetRef
                    .read(playlistsProvider.notifier)
                    .deletePlaylist(playlist.id);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            _OptionTile(
              icon: Icons.close_rounded,
              label: 'Cancel',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
