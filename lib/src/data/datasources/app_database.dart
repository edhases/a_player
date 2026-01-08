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
  TextColumn get path => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get duration => integer()();
  TextColumn get folderPath => text()();
  TextColumn get artworkUri => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get mediaStoreId => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {path}, // path is unique
  ];
}

// YouTube track table for caching metadata and offline support
@DataClassName('YouTubeTrack')
class YouTubeTracks extends Table {
  TextColumn get videoId => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get thumbnailUrl => text()();
  IntColumn get duration => integer()();
  TextColumn get downloadPath => text().nullable()(); // Path to downloaded file for offline play
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()(); // When metadata was cached
  
  @override
  Set<Column> get primaryKey => {videoId};
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

@DriftDatabase(tables: [Tracks, YouTubeTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5; // Incremented from 4

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
      // YouTube tracks table disabled for now
      /*
      if (from < 5) {
        await m.createTable(youTubeTracks);
      }
      */
    },
  );

  // --- QUERY METHODS ---

  Future<List<AlbumWithArtwork>> getAllAlbums() async {
    // Optimized: Use SQL GROUP BY instead of loading all tracks into memory
    final query = selectOnly(tracks)
      ..addColumns([tracks.album, tracks.artist, tracks.path, tracks.mediaStoreId])
      ..groupBy([tracks.album]);

    final rows = await query.get();

    return rows.map((row) {
      return AlbumWithArtwork(
        title: row.read(tracks.album) ?? 'Unknown Album',
        artist: row.read(tracks.artist),
        artworkPath: row.read(tracks.path), // SQLite picks one random row's path from the group, which is fine for artwork
        mediaStoreId: row.read(tracks.mediaStoreId),
      );
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  Future<List<Artist>> getAllArtists() async {
    // Optimized: Use SQL DISTINCT instead of loading all tracks
    final query = selectOnly(tracks, distinct: true)
      ..addColumns([tracks.artist])
      ..where(tracks.artist.isNotNull());

    final rows = await query.get();

    return rows
        .map((row) => Artist(name: row.read(tracks.artist)!))
        .toList()
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

  // --- YOUTUBE TRACK METHODS ---
  // These methods are disabled for now due to Drift database structure changes
  /*
  
  // Insert or update a YouTube track
  Future<void> upsertYouTubeTrack(YouTubeTrack track) async {
    await into(youTubeTracks).insert(
      track,
      onConflict: DoUpdate((old) => track),
    );
  }
  
  // Get a YouTube track by video ID
  Future<YouTubeTrack?> getYouTubeTrack(String videoId) {
    return (select(youTubeTracks)..where((t) => t.videoId.equals(videoId))).getSingleOrNull();
  }
  
  // Get all downloaded tracks
  Stream<List<YouTubeTrack>> watchDownloadedTracks() {
    return (select(youTubeTracks)..where((t) => t.downloadPath.isNotNull())).watch();
  }
  
  // Update download path for offline access
  Future<void> updateDownloadPath(String videoId, String? path) async {
    await (update(youTubeTracks)..where((t) => t.videoId.equals(videoId))).write(
      YouTubeTracksCompanion(downloadPath: Value(path)),
    );
  }
  
  // Mark as recently played
  Future<void> markAsPlayed(String videoId) async {
    await (update(youTubeTracks)..where((t) => t.videoId.equals(videoId))).write(
      YouTubeTracksCompanion(lastPlayed: Value(DateTime.now())),
    );
  }
  */
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
