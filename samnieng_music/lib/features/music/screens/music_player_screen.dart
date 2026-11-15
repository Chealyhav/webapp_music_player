import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/core/utils/audio_logger.dart';
import 'package:samnieng_music/core/utils/format_utils.dart';
import 'package:samnieng_music/data/models/song.dart';
import 'package:samnieng_music/features/favorites/state/favorites_state.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';
import 'package:samnieng_music/features/playlist/widgets/add_to_playlist_sheet.dart';
import 'package:samnieng_music/services/storage/downloaded_song_db.dart';

class MusicPlayerScreen extends ConsumerStatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen> {
  double? _dragValue;
  bool _showQueue = false;

  Future<void> _togglePlayback() async {
    final audioService = ref.read(audioPlayerServiceProvider);
    final isPlaying = ref.read(isPlayingProvider).value ?? false;
    if (isPlaying) {
      await audioService.pause();
    } else {
      await audioService.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'No song selected',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final isPlaying = isPlayingAsync.value ?? false;
    final livePosition = positionAsync.value ?? Duration.zero;
    final totalDuration =
        (durationAsync.value != null && durationAsync.value! > Duration.zero)
        ? durationAsync.value!
        : (song.duration > Duration.zero ? song.duration : Duration.zero);

    final isShuffle = ref.watch(shuffleEnabledProvider);
    final isRepeat = ref.watch(repeatEnabledProvider);
    final queue = ref.watch(playbackQueueProvider);
    final queueIndex = ref.watch(queueIndexProvider);
    final volume = ref.watch(volumeProvider);

    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(song.id);
    final playbackError = ref.watch(playbackErrorProvider);

    final maxSeconds = totalDuration.inSeconds > 0
        ? totalDuration.inSeconds.toDouble()
        : 1.0;
    final currentSeconds = (_dragValue ?? livePosition.inSeconds.toDouble())
        .clamp(0.0, maxSeconds);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.3),
                  AppColors.background,
                  AppColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 32,
                          ),
                          color: AppColors.textPrimary,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Now Playing',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz_rounded),
                          color: AppColors.textPrimary,
                          onPressed: () => _showPlayerOptions(context, song),
                        ),
                      ],
                    ),
                  ),

                  // ── Main scrollable content ──────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // ── Album artwork ──────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 36,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: _buildArtwork(song),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Title + Artist + Error banner ───────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                                if (playbackError != null &&
                                    playbackError.trackId == song.id) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.error.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            playbackError.errorMessage.contains(
                                                  '403',
                                                )
                                                ? 'Audio source rejected the request (HTTP 403). Playback stopped.'
                                                : 'Could not play this track. Playback stopped.',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Progress Slider ─────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: AppColors.surface,
                                    thumbColor: Colors.white,
                                    overlayColor: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  child: Slider(
                                    value: currentSeconds,
                                    max: maxSeconds,
                                    onChanged: (val) {
                                      setState(() => _dragValue = val);
                                    },
                                    onChangeEnd: (val) {
                                      ref
                                          .read(audioPlayerServiceProvider)
                                          .seek(Duration(seconds: val.toInt()));
                                      setState(() => _dragValue = null);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        FormatUtils.formatDuration(
                                          _dragValue != null
                                              ? Duration(
                                                  seconds: _dragValue!.toInt(),
                                                )
                                              : livePosition,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        FormatUtils.formatDuration(
                                          totalDuration,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Playback Controls ───────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Shuffle
                                IconButton(
                                  iconSize: 26,
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    color: isShuffle
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                  onPressed: () {
                                    ref
                                            .read(
                                              shuffleEnabledProvider.notifier,
                                            )
                                            .state =
                                        !isShuffle;
                                  },
                                ),

                                // Previous
                                IconButton(
                                  iconSize: 40,
                                  icon: const Icon(
                                    Icons.skip_previous_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  onPressed: () {
                                    if (livePosition.inSeconds > 3) {
                                      ref
                                          .read(audioPlayerServiceProvider)
                                          .seek(Duration.zero);
                                    } else {
                                      playQueueOffset(ref, -1);
                                    }
                                  },
                                ),

                                // Play / Pause
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    iconSize: 36,
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayback,
                                  ),
                                ),

                                // Next
                                IconButton(
                                  iconSize: 40,
                                  icon: const Icon(
                                    Icons.skip_next_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  onPressed: () => playQueueOffset(ref, 1),
                                ),

                                // Repeat
                                IconButton(
                                  iconSize: 26,
                                  icon: Icon(
                                    isRepeat
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    color: isRepeat
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                  onPressed: () {
                                    ref
                                            .read(
                                              repeatEnabledProvider.notifier,
                                            )
                                            .state =
                                        !isRepeat;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Volume Control (native only) ────────────────
                          if (!kIsWeb)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.volume_mute_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 2,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 5,
                                        ),
                                        activeTrackColor: AppColors.textMuted,
                                        inactiveTrackColor: AppColors.surface,
                                        thumbColor: AppColors.textSecondary,
                                        overlayColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                      ),
                                      child: Slider(
                                        value: volume,
                                        min: 0.0,
                                        max: 1.0,
                                        onChanged: (val) {
                                          ref
                                                  .read(volumeProvider.notifier)
                                                  .state =
                                              val;
                                          ref
                                              .read(audioPlayerServiceProvider)
                                              .setVolume(val);
                                        },
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.volume_up_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // ── Action Buttons ──────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(favoritesProvider.notifier)
                                        .toggleFavorite(song);
                                  },
                                  child: _actionButton(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    'Favorite',
                                    highlight: isFav,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showAddToPlaylistSheet(context, ref, song);
                                  },
                                  child: _actionButton(
                                    Icons.playlist_add_rounded,
                                    'Playlist',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await DownloadedSongDatabase.instance
                                        .saveSong(song);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${song.title} saved to downloads',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  child: _actionButton(
                                    Icons.download_rounded,
                                    'Download',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Up Next Queue ───────────────────────────────
                          if (queue.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Up Next',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${queue.length} songs',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _showQueue = !_showQueue,
                                    ),
                                    child: Text(
                                      _showQueue ? 'Hide' : 'Show',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_showQueue)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                itemCount: queue.length,
                                itemBuilder: (ctx, i) {
                                  final qSong = queue[i];
                                  final isCurrent = i == queueIndex;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        color: AppColors.surfaceVariant,
                                        child: qSong.artworkUrl != null
                                            ? Image.network(
                                                qSong.artworkUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                      Icons.music_note,
                                                      color: AppColors.primary,
                                                      size: 20,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.music_note,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      qSong.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      qSong.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    trailing: isCurrent
                                        ? const Icon(
                                            Icons.equalizer_rounded,
                                            color: AppColors.primary,
                                            size: 18,
                                          )
                                        : null,
                                    onTap: () {
                                      startPlayback(ref, qSong, queue: queue);
                                    },
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtwork(Song song) {
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      return Image.network(
        song.artworkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surface,
          child: const Icon(
            Icons.music_note_rounded,
            size: 80,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.music_note_rounded,
        size: 80,
        color: AppColors.primary,
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, {bool highlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: highlight ? AppColors.primary : AppColors.textSecondary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: highlight ? AppColors.primary : AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showPlayerOptions(BuildContext context, Song song) {
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
              const SizedBox(height: 16),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.playlist_add_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Add to Playlist',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddToPlaylistSheet(context, ref, song);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.bug_report_outlined,
                  color: AppColors.warning,
                ),
                title: const Text(
                  'Playback Logs & Track Errors',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showErrorLogsDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                ),
                title: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorLogsDialog(BuildContext context) {
    final recentErrors = AudioLogger.recentErrors;
    final recentLogs = AudioLogger.recentLogs;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Playback & Audio Convert Logs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.surfaceVariant),
              Text(
                'Track Errors: ${recentErrors.length} | Total Logs: ${recentLogs.length}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: recentLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'No errors or logs recorded yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: recentLogs.length,
                        itemBuilder: (c, idx) {
                          final log = recentLogs[recentLogs.length - 1 - idx];
                          Color logColor = AppColors.textSecondary;
                          if (log.level == AudioLogLevel.error) {
                            logColor = AppColors.error;
                          } else if (log.level == AudioLogLevel.warning) {
                            logColor = AppColors.warning;
                          } else if (log.tag.contains('SUCCESS')) {
                            logColor = AppColors.success;
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '[${log.category.name.toUpperCase()}] ${log.tag}',
                                      style: TextStyle(
                                        color: logColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  log.message,
                                  style: TextStyle(
                                    color: logColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
