/// Domain entity for radio stations.
/// 
/// This decouples the presentation layer from Drift's RadioStation model.
class LocalRadioStation {
  final int id;
  final String name;
  final String streamUrl;
  final String? imageUrl;

  const LocalRadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.imageUrl,
  });

  LocalRadioStation copyWith({
    int? id,
    String? name,
    String? streamUrl,
    String? imageUrl,
  }) {
    return LocalRadioStation(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalRadioStation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          streamUrl == other.streamUrl;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ streamUrl.hashCode;

  @override
  String toString() => 'LocalRadioStation(id: $id, name: $name)';
}
