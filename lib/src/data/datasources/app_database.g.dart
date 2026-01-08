// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
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
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _mediaStoreIdMeta =
      const VerificationMeta('mediaStoreId');
  @override
  late final GeneratedColumn<int> mediaStoreId = GeneratedColumn<int>(
      'media_store_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        path,
        title,
        artist,
        album,
        duration,
        folderPath,
        artworkUri,
        isFavorite,
        mediaStoreId
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
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
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
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('media_store_id')) {
      context.handle(
          _mediaStoreIdMeta,
          mediaStoreId.isAcceptableOrUnknown(
              data['media_store_id']!, _mediaStoreIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {path},
      ];
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist']),
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      folderPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_path'])!,
      artworkUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artwork_uri']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      mediaStoreId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_store_id']),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final int duration;
  final String folderPath;
  final String? artworkUri;
  final bool isFavorite;
  final int? mediaStoreId;
  const Track(
      {required this.path,
      required this.title,
      this.artist,
      this.album,
      required this.duration,
      required this.folderPath,
      this.artworkUri,
      required this.isFavorite,
      this.mediaStoreId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    map['duration'] = Variable<int>(duration);
    map['folder_path'] = Variable<String>(folderPath);
    if (!nullToAbsent || artworkUri != null) {
      map['artwork_uri'] = Variable<String>(artworkUri);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || mediaStoreId != null) {
      map['media_store_id'] = Variable<int>(mediaStoreId);
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      path: Value(path),
      title: Value(title),
      artist:
          artist == null && nullToAbsent ? const Value.absent() : Value(artist),
      album:
          album == null && nullToAbsent ? const Value.absent() : Value(album),
      duration: Value(duration),
      folderPath: Value(folderPath),
      artworkUri: artworkUri == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUri),
      isFavorite: Value(isFavorite),
      mediaStoreId: mediaStoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaStoreId),
    );
  }

  factory Track.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      path: serializer.fromJson<String>(json['path']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      duration: serializer.fromJson<int>(json['duration']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      artworkUri: serializer.fromJson<String?>(json['artworkUri']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      mediaStoreId: serializer.fromJson<int?>(json['mediaStoreId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'duration': serializer.toJson<int>(duration),
      'folderPath': serializer.toJson<String>(folderPath),
      'artworkUri': serializer.toJson<String?>(artworkUri),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'mediaStoreId': serializer.toJson<int?>(mediaStoreId),
    };
  }

  Track copyWith(
          {String? path,
          String? title,
          Value<String?> artist = const Value.absent(),
          Value<String?> album = const Value.absent(),
          int? duration,
          String? folderPath,
          Value<String?> artworkUri = const Value.absent(),
          bool? isFavorite,
          Value<int?> mediaStoreId = const Value.absent()}) =>
      Track(
        path: path ?? this.path,
        title: title ?? this.title,
        artist: artist.present ? artist.value : this.artist,
        album: album.present ? album.value : this.album,
        duration: duration ?? this.duration,
        folderPath: folderPath ?? this.folderPath,
        artworkUri: artworkUri.present ? artworkUri.value : this.artworkUri,
        isFavorite: isFavorite ?? this.isFavorite,
        mediaStoreId:
            mediaStoreId.present ? mediaStoreId.value : this.mediaStoreId,
      );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      path: data.path.present ? data.path.value : this.path,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      duration: data.duration.present ? data.duration.value : this.duration,
      folderPath:
          data.folderPath.present ? data.folderPath.value : this.folderPath,
      artworkUri:
          data.artworkUri.present ? data.artworkUri.value : this.artworkUri,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      mediaStoreId: data.mediaStoreId.present
          ? data.mediaStoreId.value
          : this.mediaStoreId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('duration: $duration, ')
          ..write('folderPath: $folderPath, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('mediaStoreId: $mediaStoreId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, title, artist, album, duration,
      folderPath, artworkUri, isFavorite, mediaStoreId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.path == this.path &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.duration == this.duration &&
          other.folderPath == this.folderPath &&
          other.artworkUri == this.artworkUri &&
          other.isFavorite == this.isFavorite &&
          other.mediaStoreId == this.mediaStoreId);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<String> path;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<int> duration;
  final Value<String> folderPath;
  final Value<String?> artworkUri;
  final Value<bool> isFavorite;
  final Value<int?> mediaStoreId;
  final Value<int> rowid;
  const TracksCompanion({
    this.path = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.duration = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.artworkUri = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.mediaStoreId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String path,
    required String title,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    required int duration,
    required String folderPath,
    this.artworkUri = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.mediaStoreId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : path = Value(path),
        title = Value(title),
        duration = Value(duration),
        folderPath = Value(folderPath);
  static Insertable<Track> custom({
    Expression<String>? path,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? duration,
    Expression<String>? folderPath,
    Expression<String>? artworkUri,
    Expression<bool>? isFavorite,
    Expression<int>? mediaStoreId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (duration != null) 'duration': duration,
      if (folderPath != null) 'folder_path': folderPath,
      if (artworkUri != null) 'artwork_uri': artworkUri,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (mediaStoreId != null) 'media_store_id': mediaStoreId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith(
      {Value<String>? path,
      Value<String>? title,
      Value<String?>? artist,
      Value<String?>? album,
      Value<int>? duration,
      Value<String>? folderPath,
      Value<String?>? artworkUri,
      Value<bool>? isFavorite,
      Value<int?>? mediaStoreId,
      Value<int>? rowid}) {
    return TracksCompanion(
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      folderPath: folderPath ?? this.folderPath,
      artworkUri: artworkUri ?? this.artworkUri,
      isFavorite: isFavorite ?? this.isFavorite,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
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
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (artworkUri.present) {
      map['artwork_uri'] = Variable<String>(artworkUri.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (mediaStoreId.present) {
      map['media_store_id'] = Variable<int>(mediaStoreId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('duration: $duration, ')
          ..write('folderPath: $folderPath, ')
          ..write('artworkUri: $artworkUri, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('rowid: $rowid')
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
  required String path,
  required String title,
  Value<String?> artist,
  Value<String?> album,
  required int duration,
  required String folderPath,
  Value<String?> artworkUri,
  Value<bool> isFavorite,
  Value<int?> mediaStoreId,
  Value<int> rowid,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<String> path,
  Value<String> title,
  Value<String?> artist,
  Value<String?> album,
  Value<int> duration,
  Value<String> folderPath,
  Value<String?> artworkUri,
  Value<bool> isFavorite,
  Value<int?> mediaStoreId,
  Value<int> rowid,
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
  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artworkUri => $composableBuilder(
      column: $table.artworkUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mediaStoreId => $composableBuilder(
      column: $table.mediaStoreId, builder: (column) => ColumnFilters(column));
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
  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artworkUri => $composableBuilder(
      column: $table.artworkUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mediaStoreId => $composableBuilder(
      column: $table.mediaStoreId,
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
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => column);

  GeneratedColumn<String> get artworkUri => $composableBuilder(
      column: $table.artworkUri, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<int> get mediaStoreId => $composableBuilder(
      column: $table.mediaStoreId, builder: (column) => column);
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
            Value<String> path = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<String> folderPath = const Value.absent(),
            Value<String?> artworkUri = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int?> mediaStoreId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TracksCompanion(
            path: path,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            folderPath: folderPath,
            artworkUri: artworkUri,
            isFavorite: isFavorite,
            mediaStoreId: mediaStoreId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String path,
            required String title,
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            required int duration,
            required String folderPath,
            Value<String?> artworkUri = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int?> mediaStoreId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TracksCompanion.insert(
            path: path,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            folderPath: folderPath,
            artworkUri: artworkUri,
            isFavorite: isFavorite,
            mediaStoreId: mediaStoreId,
            rowid: rowid,
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
