import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';

import 'package:samnieng_music/services/storage/preferences_service.dart';
import 'package:samnieng_music/features/music/state/music_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.samnieng.music.audio',
        androidNotificationChannelName: 'Samnieng Music',
        androidNotificationOngoing: true,
      );
    } catch (e) {
      debugPrint('JustAudioBackground init: $e');
    }
  }
  
  await PreferencesService.instance.init();
  final lastSong = await PreferencesService.instance.getLastSong();

  runApp(
    ProviderScope(
      overrides: [
        if (lastSong != null)
          currentSongProvider.overrideWith((ref) => lastSong),
      ],
      child: const SamniengApp(),
    ),
  );
}
