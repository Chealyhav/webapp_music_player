import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? coverUrl;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.songs = const [],
  });

  int get songCount => songs.length;

  Duration get totalDuration => songs.fold(Duration.zero, (sum, song) => sum + song.duration);

  Playlist copyWith({
    String? id,
    String? name,
    String? coverUrl,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverUrl': coverUrl,
      'songs': songs.map((s) => s.toJson()).toList(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      coverUrl: json['coverUrl'] as String?,
      songs: (json['songs'] as List? ?? [])
          .map((e) => Song.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
