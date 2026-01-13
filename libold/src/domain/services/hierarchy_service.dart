import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import '../../data/datasources/app_database.dart';

/// A base class for entries in the hierarchical file view.
abstract class FileSystemEntry {
  /// The display name of the entry (e.g., a folder name or file name).
  final String name;
  FileSystemEntry(this.name);
}

/// Represents a folder in the hierarchy.
class FolderEntry extends FileSystemEntry {
  /// The full path to this folder.
  final String path;
  FolderEntry(String name, this.path) : super(name);
}

/// Represents a music track file in the hierarchy.
class TrackEntry extends FileSystemEntry {
  /// The full track data from the database.
  final Track track;
  TrackEntry(String name, this.track) : super(name);
}

/// A service that transforms a flat list of tracks into a browsable
/// hierarchical structure of folders and files.
class HierarchyService {
  /// Returns a list of [FileSystemEntry] objects for a given directory path.
  ///
  /// [allTracks] is the complete list of tracks from the database.
  /// [path] is the directory whose contents are to be listed. A path of '.'
  /// represents the root level.
  List<FileSystemEntry> getEntriesForPath(List<Track> allTracks, String path) {
    final entries = <FileSystemEntry>[];
    final directChildren = <String>{}; // Used to avoid duplicate folder entries

    for (final track in allTracks) {
      final trackDir = p.dirname(track.path);

      if (path == '.') {
        // For the root, we want to find the top-level folders.
        final parts = p.split(trackDir);
        if (parts.length > 1) {
          final rootFolder = parts[1]; // The first folder after the root '/'
          final folderPath = p.join(parts[0], rootFolder);
          if (directChildren.add(folderPath)) {
            entries.add(FolderEntry(rootFolder, folderPath));
          }
        }
      } else if (p.isWithin(path, trackDir) || path == trackDir) {
        // We are inside a specific folder.
        final relativePath = p.relative(trackDir, from: path);

        if (relativePath == '.') {
          // This track is a direct child of the current path.
          entries.add(TrackEntry(p.basename(track.path), track));
        } else {
          // This track is in a subdirectory. Add the subdirectory.
          final subfolderName = p.split(relativePath).first;
          final folderPath = p.join(path, subfolderName);
          if (directChildren.add(folderPath)) {
            entries.add(FolderEntry(subfolderName, folderPath));
          }
        }
      }
    }

    // Sort entries: folders first, then alphabetically.
    entries.sort((a, b) {
      if (a is FolderEntry && b is TrackEntry) {
        return -1;
      }
      if (a is TrackEntry && b is FolderEntry) {
        return 1;
      }
      return compareAsciiLowerCase(a.name, b.name);
    });

    return entries;
  }
}
