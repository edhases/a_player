/// Domain entity for local artist.
/// 
/// This decouples the presentation layer from Drift's Artist model.
class LocalArtist {
  final String name;
  final String? imageUrl;
  final int trackCount;
  final int albumCount;

  const LocalArtist({
    required this.name,
    this.imageUrl,
    this.trackCount = 0,
    this.albumCount = 0,
  });

  LocalArtist copyWith({
    String? name,
    String? imageUrl,
    int? trackCount,
    int? albumCount,
  }) {
    return LocalArtist(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      trackCount: trackCount ?? this.trackCount,
      albumCount: albumCount ?? this.albumCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalArtist &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'LocalArtist(name: $name)';
}
