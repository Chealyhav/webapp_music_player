import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'core/theme/app_theme.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/music/screens/music_library_screen.dart';
import 'features/music/state/music_state.dart';
import 'features/music/widgets/mini_player.dart';
import 'features/playlist/screens/playlist_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/splash/screens/loading_screen.dart';

class SamniengApp extends StatelessWidget {
  const SamniengApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samnieng Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LoadingScreen(),
    );
  }
}

class MainAppScaffold extends ConsumerStatefulWidget {
  const MainAppScaffold({super.key});

  @override
  ConsumerState<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends ConsumerState<MainAppScaffold> {
  int _currentIndex = 0;

  // Web only: watch for controller being created so we rebuild and embed it
  YoutubePlayerController? _webController;
  Timer? _webControllerPoll;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    PlaylistScreen(),
    MusicLibraryScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Poll every 500ms to pick up the controller once a song starts playing
      _webControllerPoll = Timer.periodic(const Duration(milliseconds: 500), (
        _,
      ) {
        final audioService = ref.read(audioPlayerServiceProvider);
        final ctrl = audioService.webPlayer.controller;
        if (ctrl != null && ctrl != _webController) {
          setState(() => _webController = ctrl);
        }
      });
    }
  }

  @override
  void dispose() {
    _webControllerPoll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep autoAdvance active across the entire app
    ref.watch(autoAdvanceProvider);
    ref.listen(playbackErrorProvider, (previous, next) {
      if (next == null || previous == next) return;
      final isForbidden = next.errorMessage.contains('403');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isForbidden
                  ? 'Could not play "${next.trackTitle}": the audio source rejected the request (HTTP 403). Playback stopped.'
                  : 'Could not play "${next.trackTitle}". Playback stopped; try another track.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),

          // ── Hidden YouTube iframe player (web only) ─────────────────────
          // The browser requires the <iframe> to exist in the DOM and be
          // visible (even 1px) for audio autoplay to be allowed.
          if (kIsWeb && _webController != null)
            Positioned(
              left: 0,
              bottom: 0,
              width: 1,
              height: 1,
              child: YoutubePlayerScaffold(
                controller: _webController!,
                aspectRatio: 16 / 9,
                builder: (context, player) => player,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_open_outlined),
                activeIcon: Icon(Icons.folder_open),
                label: 'Local',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
