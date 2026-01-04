// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _folderPathMeta =
      const VerificationMeta('folderPath');
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
      'folder_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artworkUriMeta =
      const VerificationMeta('artworkUri');
  @override
  late final GeneratedColumn<String> artworkUri = GeneratedColumn<String>(
      'artwork_uri', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _remoteArtworkUriMeta =
      const VerificationMeta('remoteArtworkUri');
  @override
  late final GeneratedColumn<String> remoteArtworkUri = GeneratedColumn<String>(
      'remote_artwork_uri', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        path,
        title,
        artist,
        album,
        durationMs,
        folderPath,
        artworkUri,
        addedAt,
        sourceType,
        remoteArtworkUri
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(Insertable<Track> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
          _folderPathMeta,
          folderPath.isAcceptableOrUnknown(
              data['folder_path']!, _folderPathMeta));
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('artwork_uri')) {
      context.handle(
          _artworkUriMeta,
          artworkUri.isAcceptableOrUnknown(
              data['artwork_uri']!, _artworkUriMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('remote_artwork_uri')) {
      context.handle(
          _remoteArtworkUriMeta,
          remoteArtworkUri.isAcceptableOrUnknown(
              data['remote_artwork_uri']!, _remoteArtworkUriMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist']),
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      folderPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_path'])!,
      artworkUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artwork_uri']),
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      remoteArtworkUri: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_artwork_uri']),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final int id;
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final int durationMs;
  final String folderPath;
  final String? artworkUri;
  final DateTime addedAt;
  final String sourceType;
  final String? remoteArtworkUri;
  const Track(
      {required this.id,
      required this.path,
      required this.title,
      this.artist,
      this.album,
      required this.durationMs,
      required this.folderPath,
      this.artworkUri,
      required this.addedAt,
      required this.sourceType,
      this.remoteArtworkUri});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['folder_path'] = Variable<String>(folderPath);
    if (!nullToAbsent || artworkUri != null) {
      map['artwork_uri'] = Variable<String>(artworkUri);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || remoteArtworkUri != null) {
      map['remote_artwork_uri'] = Variable<String>(remoteArtworkUri);
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      path: Value(path),
      title: Value(title),
      artist:
          artist == null && nullToAbsent ? const Value.absent() : Value(artist),
      album:
          album == null && nullToAbsent ? const Value.absent() : Value(album),
      durationMs: Value(durationMs),
      folderPath: Value(folderPath),
      artworkUri: artworkUri == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUri),
      addedAt: Value(addedAt),
      sourceType: Value(sourceType),
      remoteArtworkUri: remoteArtworkUri == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteArtworkUri),
    );
  }

  factory Track.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      artworkUri: serializer.fromJson<String?>(json['artworkUri']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      remoteArtworkUri: serializer.fromJson<String?>(json['remoteArtworkUri']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'durationMs': serializer.toJson<int>(durationMs),
      'folderPath': serializer.toJson<String>(folderPath),
      'artworkUri': serializer.toJson<String?>(artworkUri),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'sourceType': serializer.toJson<String>(sourceType),
      'remoteArtworkUri': serializer.toJson<String?>(remoteArtworkUri),
    };
  }

  Track copyWith(
          {int? id,
          String? path,
          String? title,
          Value<String?> artist = const Value.absent(),
          Value<String?> album = const Value.absent(),
          int? durationMs,
          String? folderPath,
          Value<String?> artworkUri = const Value.absent(),
          DateTime? addedAt,
          String? sourceType,
          Value<String?> remoteArtworkUri = const Value.absent()}) =>
      Track(
        id: id ?? this.id,
        path: path ?? this.path,
        title: title ?? this.title,
        artist: artist.present ? artist.value : this.artist,
        album: album.present ? album.value : this.album,
        durationMs: durationMs ?? this.durationMs,
        folderPath: folderPath ?? this.folderPath,
        artworkUri: artworkUri.present ? artworkUri.value : this.artworkUri,
        addedAt: addedAt ?? this.addedAt,
        sourceType: sourceType ?? this.sourceType,
        remoteArtworkUri: remoteArtworkUri.present
            ? remoteArtworkUri.value
            : this.remoteArtworkUri,
      );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      folderPath:
          data.folderPath.present ? data.folderPath.value : this.folderPath,
      artworkUri:
          data.artworkUri.present ? data.artworkUri.value : this.artworkUri,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      remoteArtworkUri: data.remoteArtworkUri.present
          ? data.remoteArtworkUri.value
          : this.remoteArtworkUri,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('folderPath: $folderPath, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('addedAt: $addedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('remoteArtworkUri: $remoteArtworkUri')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, title, artist, album, durationMs,
      folderPath, artworkUri, addedAt, sourceType, remoteArtworkUri);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.path == this.path &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.durationMs == this.durationMs &&
          other.folderPath == this.folderPath &&
          other.artworkUri == this.artworkUri &&
          other.addedAt == this.addedAt &&
          other.sourceType == this.sourceType &&
          other.remoteArtworkUri == this.remoteArtworkUri);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<int> id;
  final Value<String> path;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<int> durationMs;
  final Value<String> folderPath;
  final Value<String?> artworkUri;
  final Value<DateTime> addedAt;
  final Value<String> sourceType;
  final Value<String?> remoteArtworkUri;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.artworkUri = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.remoteArtworkUri = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required String title,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    required int durationMs,
    required String folderPath,
    this.artworkUri = const Value.absent(),
    required DateTime addedAt,
    this.sourceType = const Value.absent(),
    this.remoteArtworkUri = const Value.absent(),
  })  : path = Value(path),
        title = Value(title),
        durationMs = Value(durationMs),
        folderPath = Value(folderPath),
        addedAt = Value(addedAt);
  static Insertable<Track> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? durationMs,
    Expression<String>? folderPath,
    Expression<String>? artworkUri,
    Expression<DateTime>? addedAt,
    Expression<String>? sourceType,
    Expression<String>? remoteArtworkUri,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (durationMs != null) 'duration_ms': durationMs,
      if (folderPath != null) 'folder_path': folderPath,
      if (artworkUri != null) 'artwork_uri': artworkUri,
      if (addedAt != null) 'added_at': addedAt,
      if (sourceType != null) 'source_type': sourceType,
      if (remoteArtworkUri != null) 'remote_artwork_uri': remoteArtworkUri,
    });
  }

  TracksCompanion copyWith(
      {Value<int>? id,
      Value<String>? path,
      Value<String>? title,
      Value<String?>? artist,
      Value<String?>? album,
      Value<int>? durationMs,
      Value<String>? folderPath,
      Value<String?>? artworkUri,
      Value<DateTime>? addedAt,
      Value<String>? sourceType,
      Value<String?>? remoteArtworkUri}) {
    return TracksCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      folderPath: folderPath ?? this.folderPath,
      artworkUri: artworkUri ?? this.artworkUri,
      addedAt: addedAt ?? this.addedAt,
      sourceType: sourceType ?? this.sourceType,
      remoteArtworkUri: remoteArtworkUri ?? this.remoteArtworkUri,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (artworkUri.present) {
      map['artwork_uri'] = Variable<String>(artworkUri.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (remoteArtworkUri.present) {
      map['remote_artwork_uri'] = Variable<String>(remoteArtworkUri.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('folderPath: $folderPath, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('addedAt: $addedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('remoteArtworkUri: $remoteArtworkUri')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tracks];
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  required String path,
  required String title,
  Value<String?> artist,
  Value<String?> album,
  required int durationMs,
  required String folderPath,
  Value<String?> artworkUri,
  required DateTime addedAt,
  Value<String> sourceType,
  Value<String?> remoteArtworkUri,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<String> path,
  Value<String> title,
  Value<String?> artist,
  Value<String?> album,
  Value<int> durationMs,
  Value<String> folderPath,
  Value<String?> artworkUri,
  Value<DateTime> addedAt,
  Value<String> sourceType,
  Value<String?> remoteArtworkUri,
});

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artworkUri => $composableBuilder(
      column: $table.artworkUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteArtworkUri => $composableBuilder(
      column: $table.remoteArtworkUri,
      builder: (column) => ColumnFilters(column));
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artworkUri => $composableBuilder(
      column: $table.artworkUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteArtworkUri => $composableBuilder(
      column: $table.remoteArtworkUri,
      builder: (column) => ColumnOrderings(column));
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => column);

  GeneratedColumn<String> get artworkUri => $composableBuilder(
      column: $table.artworkUri, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<String> get remoteArtworkUri => $composableBuilder(
      column: $table.remoteArtworkUri, builder: (column) => column);
}

class $$TracksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TracksTable,
    Track,
    $$TracksTableFilterComposer,
    $$TracksTableOrderingComposer,
    $$TracksTableAnnotationComposer,
    $$TracksTableCreateCompanionBuilder,
    $$TracksTableUpdateCompanionBuilder,
    (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
    Track,
    PrefetchHooks Function()> {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> folderPath = const Value.absent(),
            Value<String?> artworkUri = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<String?> remoteArtworkUri = const Value.absent(),
          }) =>
              TracksCompanion(
            id: id,
            path: path,
            title: title,
            artist: artist,
            album: album,
            durationMs: durationMs,
            folderPath: folderPath,
            artworkUri: artworkUri,
            addedAt: addedAt,
            sourceType: sourceType,
            remoteArtworkUri: remoteArtworkUri,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String path,
            required String title,
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            required int durationMs,
            required String folderPath,
            Value<String?> artworkUri = const Value.absent(),
            required DateTime addedAt,
            Value<String> sourceType = const Value.absent(),
            Value<String?> remoteArtworkUri = const Value.absent(),
          }) =>
              TracksCompanion.insert(
            id: id,
            path: path,
            title: title,
            artist: artist,
            album: album,
            durationMs: durationMs,
            folderPath: folderPath,
            artworkUri: artworkUri,
            addedAt: addedAt,
            sourceType: sourceType,
            remoteArtworkUri: remoteArtworkUri,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TracksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TracksTable,
    Track,
    $$TracksTableFilterComposer,
    $$TracksTableOrderingComposer,
    $$TracksTableAnnotationComposer,
    $$TracksTableCreateCompanionBuilder,
    $$TracksTableUpdateCompanionBuilder,
    (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
    Track,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
}
