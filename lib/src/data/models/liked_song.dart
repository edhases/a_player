import 'package:isar/isar.dart';

part 'liked_song.g.dart';

@collection
class LikedSong {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String videoId;

  late String title;
  late String artist;
  late String thumbnailUrl;

  late DateTime addedAt;
}
