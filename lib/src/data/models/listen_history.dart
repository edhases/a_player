import 'package:isar/isar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

part 'listen_history.g.dart';

@collection
class ListenHistory {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String videoId;

  late String title;
  late String artist;
  late String thumbnailUrl;

  late DateTime timestamp;

  /// Створює запис історії з об'єкта Video.
  /// Used to create a history entry from a Video object.
  static ListenHistory fromVideo(Video video) {
    return ListenHistory()
      ..videoId = video.id.value
      ..title = video.title
      ..artist = video.author
      ..thumbnailUrl = video.thumbnails.highResUrl
      ..timestamp = DateTime.now();
  }
}
