class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final String audioUrl;
  final Duration duration;
  final bool isOffline;
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    required this.audioUrl,
    required this.duration,
    this.isOffline = false,
    this.isFavorite = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    String? audioUrl,
    Duration? duration,
    bool? isOffline,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      isOffline: isOffline ?? this.isOffline,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'artworkUrl': artworkUrl,
      'audioUrl': audioUrl,
      'duration': duration.inMilliseconds,
      'isOffline': isOffline ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      artworkUrl: json['artworkUrl'] as String?,
      audioUrl: json['audioUrl'] as String,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      isOffline: (json['isOffline'] as int? ?? 0) == 1,
      isFavorite: (json['isFavorite'] as int? ?? 0) == 1,
    );
  }
}
