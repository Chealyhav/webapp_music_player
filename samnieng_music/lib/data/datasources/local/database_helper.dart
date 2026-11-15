import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Songs Table
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        artworkUrl TEXT,
        audioUrl TEXT NOT NULL,
        duration INTEGER NOT NULL,
        isOffline INTEGER NOT NULL
      )
    ''');

    // Playlists Table
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        coverUrl TEXT
      )
    ''');
    
    // Playlist Songs Table (Many-to-Many)
    await db.execute('''
      CREATE TABLE playlist_songs (
        playlistId TEXT,
        songId TEXT,
        FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE,
        PRIMARY KEY (playlistId, songId)
      )
    ''');
  }

  // --- SONGS ---

  Future<void> insertSong(Song song) async {
    final db = await instance.database;
    final data = Map<String, dynamic>.from(song.toJson())..remove('isFavorite');
    await db.insert('songs', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Song>> getAllSongs() async {
    final db = await instance.database;
    final result = await db.query('songs');
    return result.map((json) => Song.fromJson(json)).toList();
  }

  Future<void> deleteSong(String id) async {
    final db = await instance.database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  // --- PLAYLISTS ---

  Future<void> insertPlaylist(Playlist playlist) async {
    final db = await instance.database;
    await db.insert('playlists', playlist.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await instance.database;
    final result = await db.query('playlists');
    return result.map((json) => Playlist.fromJson(json)).toList();
  }
}
