import 'package:oxide_player/src/data/datasources/app_database.dart';
import 'package:oxide_player/src/domain/models/file_system_entry.dart';

class HierarchyService {
  final AppDatabase _database;

  HierarchyService(this._database);

  Future<List<FileSystemEntry>> getEntriesForPath(String path) async {
    final allTracks = await _database.select(_database.tracks).get();
    final Set<String> directSubfolders = {};
    final List<Track> directFiles = [];

    // Use a canonical path format to avoid issues with/without trailing slashes
    final normalizedPath = path == '/' ? '/' : path;

    for (final track in allTracks) {
      // Ensure the track's folder path is a descendant of the current path
      if (!track.folderPath.startsWith(normalizedPath)) {
        continue;
      }

      // Check if the track is directly in the current folder
      if (track.folderPath == normalizedPath) {
        directFiles.add(track);
        continue;
      }

      // Identify direct subfolders
      var restOfPath = track.folderPath.substring(normalizedPath.length);
      if (restOfPath.startsWith('/')) {
        restOfPath = restOfPath.substring(1);
      }
      final parts = restOfPath.split('/');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        final subfolderName = parts.first;
        final subfolderPath = normalizedPath == '/' ? '/$subfolderName' : '$normalizedPath/$subfolderName';
        directSubfolders.add(subfolderPath);
      }
    }

    final List<FileSystemEntry> entries = [];

    entries.addAll(directSubfolders.map((folderPath) {
      return FolderEntry(
        path: folderPath,
        name: folderPath.split('/').last,
      );
    }));

    entries.addAll(directFiles.map((track) {
      return TrackEntry(
        path: track.path,
        name: track.title,
        track: track,
      );
    }));

    // Sort folders first, then files, all alphabetically
    entries.sort((a, b) {
      if (a.type == b.type) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return a.type == EntryType.folder ? -1 : 1;
    });

    return entries;
  }
}
