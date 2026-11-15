import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samnieng_music/app.dart';
import 'package:samnieng_music/data/datasources/local/music_local_datasource.dart';

void main() {
  test('Mock playlist provides seed songs for the UI', () async {
    final songs = await MusicLocalDatasource().getLocalSongs();

    expect(songs, isNotEmpty);
    expect(songs.length, 3);
    expect(songs.first.title, 'Shape of You');
    expect(songs.first.artist, 'Ed Sheeran');
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SamniengApp()));
    expect(find.byType(SamniengApp), findsOneWidget);
  });
}
