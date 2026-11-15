import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/models/song.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'samnieng_music.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloads(
            id TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            album TEXT,
            artworkUrl TEXT,
            audioUrl TEXT,
            duration INTEGER,
            isOffline INTEGER,
            isFavorite INTEGER,
            filePath TEXT
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Upsert a downloaded song into SQLite.
  Future<void> saveSong(Song song, {String? filePath}) async {
    final database = await db;
    await database.insert(
      'downloads',
      {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'artworkUrl': song.artworkUrl,
        'audioUrl': song.audioUrl,
        'duration': song.duration.inMilliseconds,
        'isOffline': song.isOffline ? 1 : 0,
        'isFavorite': song.isFavorite ? 1 : 0,
        'filePath': filePath ?? song.audioUrl,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Song>> getSongs() async {
    final database = await db;
    final maps = await database.query('downloads', orderBy: 'id');
    return maps.map((m) => Song.fromJson({
      'id': m['id'],
      'title': m['title'],
      'artist': m['artist'],
      'album': m['album'],
      'artworkUrl': m['artworkUrl'],
      'audioUrl': m['filePath'] ?? m['audioUrl'],
      'duration': m['duration'],
      'isOffline': m['isOffline'],
      'isFavorite': m['isFavorite'],
    })).toList();
  }

  Future<Song?> getSong(String id) async {
    final database = await db;
    final maps = await database.query(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    return Song.fromJson({
      'id': m['id'],
      'title': m['title'],
      'artist': m['artist'],
      'album': m['album'],
      'artworkUrl': m['artworkUrl'],
      'audioUrl': m['filePath'] ?? m['audioUrl'],
      'duration': m['duration'],
      'isOffline': m['isOffline'],
      'isFavorite': m['isFavorite'],
    });
  }

  Future<bool> hasSong(String id) async {
    return (await getSong(id)) != null;
  }

  Future<void> deleteSong(String id) async {
    final database = await db;
    await database.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }
}
