import 'package:oxide_player/src/data/datasources/app_database.dart';

enum EntryType { folder, track }

abstract class FileSystemEntry {
  final String path;
  final String name;
  final EntryType type;

  FileSystemEntry({required this.path, required this.name, required this.type});
}

class FolderEntry extends FileSystemEntry {
  FolderEntry({required String path, required String name})
      : super(path: path, name: name, type: EntryType.folder);
}

class TrackEntry extends FileSystemEntry {
  final Track track;

  TrackEntry({required String path, required String name, required this.track})
      : super(path: path, name: name, type: EntryType.track);
}
