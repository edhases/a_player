import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart'; // For groupBy

part 'app_database.g.dart';

// --- TABLE DEFINITIONS ---

@DataClassName('Track')
class Tracks extends Table {
  TextColumn get path => text().unique()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get duration => integer()();
  TextColumn get folderPath => text()();
  TextColumn get artworkUri => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get mediaStoreId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {path};
}

// --- DATA WRAPPER CLASSES ---

class AlbumWithArtwork {
  final String title;
  final String? artist;
  final String? artworkPath;
  final int? mediaStoreId;

  AlbumWithArtwork({
    required this.title,
    this.artist,
    this.artworkPath,
    this.mediaStoreId,
  });
}

class Artist {
  final String name;

  Artist({required this.name});
}

// --- DATABASE CLASS ---

@DriftDatabase(tables: [Tracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tracks, tracks.folderPath);
        await m.addColumn(tracks, tracks.artworkUri);
      }
      if (from < 3) {
        await m.addColumn(tracks, tracks.isFavorite);
      }
      if (from < 4) {
        await m.addColumn(tracks, tracks.mediaStoreId);
      }
    },
  );

  // --- QUERY METHODS ---

  Future<List<AlbumWithArtwork>> getAllAlbums() async {
    final allTracks = await select(tracks).get();
    final groupedByAlbum = groupBy(allTracks, (Track track) => track.album ?? 'Unknown Album');

    return groupedByAlbum.entries.map((entry) {
      final firstTrack = entry.value.first;
      return AlbumWithArtwork(
        title: entry.key,
        artist: firstTrack.artist,
        artworkPath: firstTrack.path, // Use the path of a track for artwork
        mediaStoreId: firstTrack.mediaStoreId,
      );
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  Future<List<Artist>> getAllArtists() async {
    final allTracks = await select(tracks).get();
    final uniqueArtists = allTracks
        .where((track) => track.artist != null)
        .map((track) => track.artist!)
        .toSet()
        .toList();

    return uniqueArtists.map((name) => Artist(name: name)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<Track>> getTracksByAlbum(String albumName) {
    return (select(tracks)..where((t) => t.album.equals(albumName))).get();
  }

  Future<List<Track>> getTracksByArtist(String artistName) {
    return (select(tracks)..where((t) => t.artist.equals(artistName))).get();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String path) async {
    final track = await (select(tracks)..where((t) => t.path.equals(path))).getSingleOrNull();
    if (track != null) {
      await (update(tracks)..where((t) => t.path.equals(path))).write(
        TracksCompanion(isFavorite: Value(!track.isFavorite)),
      );
    }
  }

  // Get favorite status stream
  Stream<bool> watchIsFavorite(String path) {
    return (select(tracks)..where((t) => t.path.equals(path)))
        .watchSingle()
        .map((t) => t.isFavorite);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
