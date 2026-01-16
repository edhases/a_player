import 'package:isar/isar.dart';

part 'cached_track.g.dart';

@collection
class CachedTrack {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String videoId;

  late String filePath;
  late int fileSize; // in bytes
  late DateTime lastPlayedAt;

  late String title;
  late String artist;
  late String thumbnailUrl;
}
