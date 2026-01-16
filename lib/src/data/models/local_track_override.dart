import 'package:isar/isar.dart';

part 'local_track_override.g.dart';

@collection
class LocalTrackOverride {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String filePath;

  String? correctTitle;
  String? correctArtist;
  String? thumbnailUrl;
  String? youtubeId;

  late DateTime updatedAt;
}
