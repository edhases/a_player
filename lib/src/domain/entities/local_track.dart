import '../../core/utils/duration_formatter.dart';

/// Domain entity for local (device) music tracks.
/// Independent of database/Drift implementation.
class LocalTrack {
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final int duration; // Duration in milliseconds
  final String folderPath;
  final String? artworkUri;
  final bool isFavorite;
  final int? mediaStoreId;
  final DateTime? lastPlayed;
  final bool isExcluded;

  const LocalTrack({
    required this.path,
    required this.title,
    this.artist,
    this.album,
    required this.duration,
    required this.folderPath,
    this.artworkUri,
    this.isFavorite = false,
    this.mediaStoreId,
    this.lastPlayed,
    this.isExcluded = false,
  });

  LocalTrack copyWith({
    String? path,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? folderPath,
    String? artworkUri,
    bool? isFavorite,
    int? mediaStoreId,
    DateTime? lastPlayed,
    bool? isExcluded,
  }) {
    return LocalTrack(
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      folderPath: folderPath ?? this.folderPath,
      artworkUri: artworkUri ?? this.artworkUri,
      isFavorite: isFavorite ?? this.isFavorite,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isExcluded: isExcluded ?? this.isExcluded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTrack && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;

  /// Duration formatted as MM:SS or HH:MM:SS
  String get durationFormatted => DurationFormatter.fromMilliseconds(duration);

  Map<String, dynamic> toMap() => {
        'path': path,
        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration,
        'folderPath': folderPath,
        'artworkUri': artworkUri,
        'isFavorite': isFavorite,
        'mediaStoreId': mediaStoreId,
        'lastPlayed': lastPlayed?.toIso8601String(),
        'isExcluded': isExcluded,
      };

  factory LocalTrack.fromMap(Map<String, dynamic> map) => LocalTrack(
        path: map['path'] as String,
        title: map['title'] as String,
        artist: map['artist'] as String?,
        album: map['album'] as String?,
        duration: map['duration'] as int? ?? 0,
        folderPath: map['folderPath'] as String? ?? '',
        artworkUri: map['artworkUri'] as String?,
        isFavorite: map['isFavorite'] as bool? ?? false,
        mediaStoreId: map['mediaStoreId'] as int?,
        lastPlayed: map['lastPlayed'] != null
            ? DateTime.parse(map['lastPlayed'] as String)
            : null,
        isExcluded: map['isExcluded'] as bool? ?? false,
      );
}
