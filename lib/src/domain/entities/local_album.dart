/// Domain entity for local album.
/// 
/// This decouples the presentation layer from Drift's Album/AlbumWithArtwork model.
class LocalAlbum {
  final int? mediaStoreId;
  final String title;
  final String? artist;
  final String? artworkPath;
  final int trackCount;

  const LocalAlbum({
    this.mediaStoreId,
    required this.title,
    this.artist,
    this.artworkPath,
    this.trackCount = 0,
  });

  LocalAlbum copyWith({
    int? mediaStoreId,
    String? title,
    String? artist,
    String? artworkPath,
    int? trackCount,
  }) {
    return LocalAlbum(
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkPath: artworkPath ?? this.artworkPath,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAlbum &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist;

  @override
  int get hashCode => Object.hash(title, artist);

  @override
  String toString() => 'LocalAlbum(title: $title, artist: $artist)';
}
