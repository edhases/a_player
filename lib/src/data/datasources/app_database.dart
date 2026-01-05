import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('Track')
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get duration => integer()();
  TextColumn get folderPath => text()();
  TextColumn get sourceType => text().withDefault(const Constant('local'))();
  TextColumn get artworkUri => text().nullable()();
  TextColumn get remoteArtworkUri => text().nullable()();
  DateTimeColumn get addedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            await m.addColumn(tracks, tracks.sourceType);
            await m.addColumn(tracks, tracks.remoteArtworkUri);
          }
          if (from == 2) {
            await m.addColumn(tracks, tracks.artworkUri);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    if (await file.exists()) await file.delete(); // Temporary: delete existing DB
    return NativeDatabase(file);
  });
}
