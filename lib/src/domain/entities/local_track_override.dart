/// Domain entity for track metadata overrides.
/// 
/// This decouples the presentation layer from Drift's TrackOverride model.
class LocalTrackOverride {
  final String filePath;
  final String correctTitle;
  final String correctArtist;
  final String? thumbnailUrl;
  final String? youtubeId;

  const LocalTrackOverride({
    required this.filePath,
    required this.correctTitle,
    required this.correctArtist,
    this.thumbnailUrl,
    this.youtubeId,
  });

  LocalTrackOverride copyWith({
    String? filePath,
    String? correctTitle,
    String? correctArtist,
    String? thumbnailUrl,
    String? youtubeId,
  }) {
    return LocalTrackOverride(
      filePath: filePath ?? this.filePath,
      correctTitle: correctTitle ?? this.correctTitle,
      correctArtist: correctArtist ?? this.correctArtist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      youtubeId: youtubeId ?? this.youtubeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTrackOverride &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;

  @override
  String toString() =>
      'LocalTrackOverride(filePath: $filePath, title: $correctTitle)';
}
