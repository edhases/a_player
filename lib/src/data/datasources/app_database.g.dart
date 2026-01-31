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
  static const VerificationMeta _lastPlayedMeta =
      const VerificationMeta('lastPlayed');
  @override
  late final GeneratedColumn<DateTime> lastPlayed = GeneratedColumn<DateTime>(
      'last_played', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isExcludedMeta =
      const VerificationMeta('isExcluded');
  @override
  late final GeneratedColumn<bool> isExcluded = GeneratedColumn<bool>(
      'is_excluded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_excluded" IN (0, 1))'),
      defaultValue: const Constant(false));
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
        mediaStoreId,
        lastPlayed,
        isExcluded
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
    if (data.containsKey('last_played')) {
      context.handle(
          _lastPlayedMeta,
          lastPlayed.isAcceptableOrUnknown(
              data['last_played']!, _lastPlayedMeta));
    }
    if (data.containsKey('is_excluded')) {
      context.handle(
          _isExcludedMeta,
          isExcluded.isAcceptableOrUnknown(
              data['is_excluded']!, _isExcludedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
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
      lastPlayed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_played']),
      isExcluded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_excluded'])!,
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
  final DateTime? lastPlayed;
  final bool isExcluded;
  const Track(
      {required this.path,
      required this.title,
      this.artist,
      this.album,
      required this.duration,
      required this.folderPath,
      this.artworkUri,
      required this.isFavorite,
      this.mediaStoreId,
      this.lastPlayed,
      required this.isExcluded});
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
    if (!nullToAbsent || lastPlayed != null) {
      map['last_played'] = Variable<DateTime>(lastPlayed);
    }
    map['is_excluded'] = Variable<bool>(isExcluded);
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
      lastPlayed: lastPlayed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayed),
      isExcluded: Value(isExcluded),
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
      lastPlayed: serializer.fromJson<DateTime?>(json['lastPlayed']),
      isExcluded: serializer.fromJson<bool>(json['isExcluded']),
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
      'lastPlayed': serializer.toJson<DateTime?>(lastPlayed),
      'isExcluded': serializer.toJson<bool>(isExcluded),
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
          Value<int?> mediaStoreId = const Value.absent(),
          Value<DateTime?> lastPlayed = const Value.absent(),
          bool? isExcluded}) =>
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
        lastPlayed: lastPlayed.present ? lastPlayed.value : this.lastPlayed,
        isExcluded: isExcluded ?? this.isExcluded,
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
      lastPlayed:
          data.lastPlayed.present ? data.lastPlayed.value : this.lastPlayed,
      isExcluded:
          data.isExcluded.present ? data.isExcluded.value : this.isExcluded,
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
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('lastPlayed: $lastPlayed, ')
          ..write('isExcluded: $isExcluded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, title, artist, album, duration,
      folderPath, artworkUri, isFavorite, mediaStoreId, lastPlayed, isExcluded);
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
          other.mediaStoreId == this.mediaStoreId &&
          other.lastPlayed == this.lastPlayed &&
          other.isExcluded == this.isExcluded);
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
  final Value<DateTime?> lastPlayed;
  final Value<bool> isExcluded;
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
    this.lastPlayed = const Value.absent(),
    this.isExcluded = const Value.absent(),
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
    this.lastPlayed = const Value.absent(),
    this.isExcluded = const Value.absent(),
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
    Expression<DateTime>? lastPlayed,
    Expression<bool>? isExcluded,
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
      if (lastPlayed != null) 'last_played': lastPlayed,
      if (isExcluded != null) 'is_excluded': isExcluded,
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
      Value<DateTime?>? lastPlayed,
      Value<bool>? isExcluded,
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
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isExcluded: isExcluded ?? this.isExcluded,
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
    if (lastPlayed.present) {
      map['last_played'] = Variable<DateTime>(lastPlayed.value);
    }
    if (isExcluded.present) {
      map['is_excluded'] = Variable<bool>(isExcluded.value);
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
          ..write('lastPlayed: $lastPlayed, ')
          ..write('isExcluded: $isExcluded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $YouTubeTracksTable extends YouTubeTracks
    with TableInfo<$YouTubeTracksTable, YouTubeTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YouTubeTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta =
      const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
      'video_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailUrlMeta =
      const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
      'thumbnail_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadPathMeta =
      const VerificationMeta('downloadPath');
  @override
  late final GeneratedColumn<String> downloadPath = GeneratedColumn<String>(
      'download_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastPlayedMeta =
      const VerificationMeta('lastPlayed');
  @override
  late final GeneratedColumn<DateTime> lastPlayed = GeneratedColumn<DateTime>(
      'last_played', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
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
  static const VerificationMeta _likedAtMeta =
      const VerificationMeta('likedAt');
  @override
  late final GeneratedColumn<DateTime> likedAt = GeneratedColumn<DateTime>(
      'liked_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        videoId,
        title,
        artist,
        thumbnailUrl,
        duration,
        downloadPath,
        fileSize,
        lastPlayed,
        cachedAt,
        isFavorite,
        likedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'you_tube_tracks';
  @override
  VerificationContext validateIntegrity(Insertable<YouTubeTrack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta,
          videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
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
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
          _thumbnailUrlMeta,
          thumbnailUrl.isAcceptableOrUnknown(
              data['thumbnail_url']!, _thumbnailUrlMeta));
    } else if (isInserting) {
      context.missing(_thumbnailUrlMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('download_path')) {
      context.handle(
          _downloadPathMeta,
          downloadPath.isAcceptableOrUnknown(
              data['download_path']!, _downloadPathMeta));
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    if (data.containsKey('last_played')) {
      context.handle(
          _lastPlayedMeta,
          lastPlayed.isAcceptableOrUnknown(
              data['last_played']!, _lastPlayedMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('liked_at')) {
      context.handle(_likedAtMeta,
          likedAt.isAcceptableOrUnknown(data['liked_at']!, _likedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  YouTubeTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YouTubeTrack(
      videoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      thumbnailUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      downloadPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}download_path']),
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size']),
      lastPlayed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_played']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      likedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}liked_at']),
    );
  }

  @override
  $YouTubeTracksTable createAlias(String alias) {
    return $YouTubeTracksTable(attachedDatabase, alias);
  }
}

class YouTubeTrack extends DataClass implements Insertable<YouTubeTrack> {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final int duration;
  final String? downloadPath;
  final int? fileSize;
  final DateTime? lastPlayed;
  final DateTime cachedAt;
  final bool isFavorite;
  final DateTime? likedAt;
  const YouTubeTrack(
      {required this.videoId,
      required this.title,
      required this.artist,
      required this.thumbnailUrl,
      required this.duration,
      this.downloadPath,
      this.fileSize,
      this.lastPlayed,
      required this.cachedAt,
      required this.isFavorite,
      this.likedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || downloadPath != null) {
      map['download_path'] = Variable<String>(downloadPath);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || lastPlayed != null) {
      map['last_played'] = Variable<DateTime>(lastPlayed);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || likedAt != null) {
      map['liked_at'] = Variable<DateTime>(likedAt);
    }
    return map;
  }

  YouTubeTracksCompanion toCompanion(bool nullToAbsent) {
    return YouTubeTracksCompanion(
      videoId: Value(videoId),
      title: Value(title),
      artist: Value(artist),
      thumbnailUrl: Value(thumbnailUrl),
      duration: Value(duration),
      downloadPath: downloadPath == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadPath),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      lastPlayed: lastPlayed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayed),
      cachedAt: Value(cachedAt),
      isFavorite: Value(isFavorite),
      likedAt: likedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(likedAt),
    );
  }

  factory YouTubeTrack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YouTubeTrack(
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      thumbnailUrl: serializer.fromJson<String>(json['thumbnailUrl']),
      duration: serializer.fromJson<int>(json['duration']),
      downloadPath: serializer.fromJson<String?>(json['downloadPath']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      lastPlayed: serializer.fromJson<DateTime?>(json['lastPlayed']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      likedAt: serializer.fromJson<DateTime?>(json['likedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'thumbnailUrl': serializer.toJson<String>(thumbnailUrl),
      'duration': serializer.toJson<int>(duration),
      'downloadPath': serializer.toJson<String?>(downloadPath),
      'fileSize': serializer.toJson<int?>(fileSize),
      'lastPlayed': serializer.toJson<DateTime?>(lastPlayed),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'likedAt': serializer.toJson<DateTime?>(likedAt),
    };
  }

  YouTubeTrack copyWith(
          {String? videoId,
          String? title,
          String? artist,
          String? thumbnailUrl,
          int? duration,
          Value<String?> downloadPath = const Value.absent(),
          Value<int?> fileSize = const Value.absent(),
          Value<DateTime?> lastPlayed = const Value.absent(),
          DateTime? cachedAt,
          bool? isFavorite,
          Value<DateTime?> likedAt = const Value.absent()}) =>
      YouTubeTrack(
        videoId: videoId ?? this.videoId,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        duration: duration ?? this.duration,
        downloadPath:
            downloadPath.present ? downloadPath.value : this.downloadPath,
        fileSize: fileSize.present ? fileSize.value : this.fileSize,
        lastPlayed: lastPlayed.present ? lastPlayed.value : this.lastPlayed,
        cachedAt: cachedAt ?? this.cachedAt,
        isFavorite: isFavorite ?? this.isFavorite,
        likedAt: likedAt.present ? likedAt.value : this.likedAt,
      );
  YouTubeTrack copyWithCompanion(YouTubeTracksCompanion data) {
    return YouTubeTrack(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      duration: data.duration.present ? data.duration.value : this.duration,
      downloadPath: data.downloadPath.present
          ? data.downloadPath.value
          : this.downloadPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      lastPlayed:
          data.lastPlayed.present ? data.lastPlayed.value : this.lastPlayed,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      likedAt: data.likedAt.present ? data.likedAt.value : this.likedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YouTubeTrack(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('duration: $duration, ')
          ..write('downloadPath: $downloadPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('lastPlayed: $lastPlayed, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('likedAt: $likedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      videoId,
      title,
      artist,
      thumbnailUrl,
      duration,
      downloadPath,
      fileSize,
      lastPlayed,
      cachedAt,
      isFavorite,
      likedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YouTubeTrack &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.duration == this.duration &&
          other.downloadPath == this.downloadPath &&
          other.fileSize == this.fileSize &&
          other.lastPlayed == this.lastPlayed &&
          other.cachedAt == this.cachedAt &&
          other.isFavorite == this.isFavorite &&
          other.likedAt == this.likedAt);
}

class YouTubeTracksCompanion extends UpdateCompanion<YouTubeTrack> {
  final Value<String> videoId;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> thumbnailUrl;
  final Value<int> duration;
  final Value<String?> downloadPath;
  final Value<int?> fileSize;
  final Value<DateTime?> lastPlayed;
  final Value<DateTime> cachedAt;
  final Value<bool> isFavorite;
  final Value<DateTime?> likedAt;
  final Value<int> rowid;
  const YouTubeTracksCompanion({
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.downloadPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.lastPlayed = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.likedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  YouTubeTracksCompanion.insert({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int duration,
    this.downloadPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.lastPlayed = const Value.absent(),
    required DateTime cachedAt,
    this.isFavorite = const Value.absent(),
    this.likedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : videoId = Value(videoId),
        title = Value(title),
        artist = Value(artist),
        thumbnailUrl = Value(thumbnailUrl),
        duration = Value(duration),
        cachedAt = Value(cachedAt);
  static Insertable<YouTubeTrack> custom({
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? thumbnailUrl,
    Expression<int>? duration,
    Expression<String>? downloadPath,
    Expression<int>? fileSize,
    Expression<DateTime>? lastPlayed,
    Expression<DateTime>? cachedAt,
    Expression<bool>? isFavorite,
    Expression<DateTime>? likedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (duration != null) 'duration': duration,
      if (downloadPath != null) 'download_path': downloadPath,
      if (fileSize != null) 'file_size': fileSize,
      if (lastPlayed != null) 'last_played': lastPlayed,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (likedAt != null) 'liked_at': likedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  YouTubeTracksCompanion copyWith(
      {Value<String>? videoId,
      Value<String>? title,
      Value<String>? artist,
      Value<String>? thumbnailUrl,
      Value<int>? duration,
      Value<String?>? downloadPath,
      Value<int?>? fileSize,
      Value<DateTime?>? lastPlayed,
      Value<DateTime>? cachedAt,
      Value<bool>? isFavorite,
      Value<DateTime?>? likedAt,
      Value<int>? rowid}) {
    return YouTubeTracksCompanion(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      downloadPath: downloadPath ?? this.downloadPath,
      fileSize: fileSize ?? this.fileSize,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      cachedAt: cachedAt ?? this.cachedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      likedAt: likedAt ?? this.likedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (downloadPath.present) {
      map['download_path'] = Variable<String>(downloadPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (lastPlayed.present) {
      map['last_played'] = Variable<DateTime>(lastPlayed.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (likedAt.present) {
      map['liked_at'] = Variable<DateTime>(likedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YouTubeTracksCompanion(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('duration: $duration, ')
          ..write('downloadPath: $downloadPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('lastPlayed: $lastPlayed, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('likedAt: $likedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HomeCacheTable extends HomeCache
    with TableInfo<$HomeCacheTable, HomeCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomeCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, data, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'home_cache';
  @override
  VerificationContext validateIntegrity(Insertable<HomeCacheEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HomeCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HomeCacheEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $HomeCacheTable createAlias(String alias) {
    return $HomeCacheTable(attachedDatabase, alias);
  }
}

class HomeCacheEntry extends DataClass implements Insertable<HomeCacheEntry> {
  final int id;
  final String data;
  final DateTime timestamp;
  const HomeCacheEntry(
      {required this.id, required this.data, required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data'] = Variable<String>(data);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  HomeCacheCompanion toCompanion(bool nullToAbsent) {
    return HomeCacheCompanion(
      id: Value(id),
      data: Value(data),
      timestamp: Value(timestamp),
    );
  }

  factory HomeCacheEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HomeCacheEntry(
      id: serializer.fromJson<int>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'data': serializer.toJson<String>(data),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  HomeCacheEntry copyWith({int? id, String? data, DateTime? timestamp}) =>
      HomeCacheEntry(
        id: id ?? this.id,
        data: data ?? this.data,
        timestamp: timestamp ?? this.timestamp,
      );
  HomeCacheEntry copyWithCompanion(HomeCacheCompanion data) {
    return HomeCacheEntry(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HomeCacheEntry(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, data, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeCacheEntry &&
          other.id == this.id &&
          other.data == this.data &&
          other.timestamp == this.timestamp);
}

class HomeCacheCompanion extends UpdateCompanion<HomeCacheEntry> {
  final Value<int> id;
  final Value<String> data;
  final Value<DateTime> timestamp;
  const HomeCacheCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  HomeCacheCompanion.insert({
    this.id = const Value.absent(),
    required String data,
    required DateTime timestamp,
  })  : data = Value(data),
        timestamp = Value(timestamp);
  static Insertable<HomeCacheEntry> custom({
    Expression<int>? id,
    Expression<String>? data,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  HomeCacheCompanion copyWith(
      {Value<int>? id, Value<String>? data, Value<DateTime>? timestamp}) {
    return HomeCacheCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomeCacheCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $RadioStationsTable extends RadioStations
    with TableInfo<$RadioStationsTable, RadioStation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RadioStationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, streamUrl, imageUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'radio_stations';
  @override
  VerificationContext validateIntegrity(Insertable<RadioStation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RadioStation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RadioStation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
    );
  }

  @override
  $RadioStationsTable createAlias(String alias) {
    return $RadioStationsTable(attachedDatabase, alias);
  }
}

class RadioStation extends DataClass implements Insertable<RadioStation> {
  final int id;
  final String name;
  final String streamUrl;
  final String? imageUrl;
  const RadioStation(
      {required this.id,
      required this.name,
      required this.streamUrl,
      this.imageUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  RadioStationsCompanion toCompanion(bool nullToAbsent) {
    return RadioStationsCompanion(
      id: Value(id),
      name: Value(name),
      streamUrl: Value(streamUrl),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory RadioStation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RadioStation(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  RadioStation copyWith(
          {int? id,
          String? name,
          String? streamUrl,
          Value<String?> imageUrl = const Value.absent()}) =>
      RadioStation(
        id: id ?? this.id,
        name: name ?? this.name,
        streamUrl: streamUrl ?? this.streamUrl,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
      );
  RadioStation copyWithCompanion(RadioStationsCompanion data) {
    return RadioStation(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RadioStation(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, streamUrl, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RadioStation &&
          other.id == this.id &&
          other.name == this.name &&
          other.streamUrl == this.streamUrl &&
          other.imageUrl == this.imageUrl);
}

class RadioStationsCompanion extends UpdateCompanion<RadioStation> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> streamUrl;
  final Value<String?> imageUrl;
  const RadioStationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  RadioStationsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String streamUrl,
    this.imageUrl = const Value.absent(),
  })  : name = Value(name),
        streamUrl = Value(streamUrl);
  static Insertable<RadioStation> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? streamUrl,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  RadioStationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? streamUrl,
      Value<String?>? imageUrl}) {
    return RadioStationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RadioStationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $PlaybackLogTable extends PlaybackLog
    with TableInfo<$PlaybackLogTable, PlaybackLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _videoIdMeta =
      const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
      'video_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playedAtMeta =
      const VerificationMeta('playedAt');
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
      'played_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, videoId, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_log';
  @override
  VerificationContext validateIntegrity(Insertable<PlaybackLogEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta,
          videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(_playedAtMeta,
          playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta));
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackLogEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      videoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      playedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}played_at'])!,
    );
  }

  @override
  $PlaybackLogTable createAlias(String alias) {
    return $PlaybackLogTable(attachedDatabase, alias);
  }
}

class PlaybackLogEntry extends DataClass
    implements Insertable<PlaybackLogEntry> {
  final int id;
  final String videoId;
  final DateTime playedAt;
  const PlaybackLogEntry(
      {required this.id, required this.videoId, required this.playedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['video_id'] = Variable<String>(videoId);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  PlaybackLogCompanion toCompanion(bool nullToAbsent) {
    return PlaybackLogCompanion(
      id: Value(id),
      videoId: Value(videoId),
      playedAt: Value(playedAt),
    );
  }

  factory PlaybackLogEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackLogEntry(
      id: serializer.fromJson<int>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'videoId': serializer.toJson<String>(videoId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  PlaybackLogEntry copyWith({int? id, String? videoId, DateTime? playedAt}) =>
      PlaybackLogEntry(
        id: id ?? this.id,
        videoId: videoId ?? this.videoId,
        playedAt: playedAt ?? this.playedAt,
      );
  PlaybackLogEntry copyWithCompanion(PlaybackLogCompanion data) {
    return PlaybackLogEntry(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackLogEntry(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, videoId, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackLogEntry &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.playedAt == this.playedAt);
}

class PlaybackLogCompanion extends UpdateCompanion<PlaybackLogEntry> {
  final Value<int> id;
  final Value<String> videoId;
  final Value<DateTime> playedAt;
  const PlaybackLogCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  PlaybackLogCompanion.insert({
    this.id = const Value.absent(),
    required String videoId,
    required DateTime playedAt,
  })  : videoId = Value(videoId),
        playedAt = Value(playedAt);
  static Insertable<PlaybackLogEntry> custom({
    Expression<int>? id,
    Expression<String>? videoId,
    Expression<DateTime>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  PlaybackLogCompanion copyWith(
      {Value<int>? id, Value<String>? videoId, Value<DateTime>? playedAt}) {
    return PlaybackLogCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackLogCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackOverridesTable extends TrackOverrides
    with TableInfo<$TrackOverridesTable, TrackOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correctTitleMeta =
      const VerificationMeta('correctTitle');
  @override
  late final GeneratedColumn<String> correctTitle = GeneratedColumn<String>(
      'correct_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _correctArtistMeta =
      const VerificationMeta('correctArtist');
  @override
  late final GeneratedColumn<String> correctArtist = GeneratedColumn<String>(
      'correct_artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailUrlMeta =
      const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
      'thumbnail_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _youtubeIdMeta =
      const VerificationMeta('youtubeId');
  @override
  late final GeneratedColumn<String> youtubeId = GeneratedColumn<String>(
      'youtube_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        filePath,
        correctTitle,
        correctArtist,
        thumbnailUrl,
        youtubeId,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_overrides';
  @override
  VerificationContext validateIntegrity(Insertable<TrackOverride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('correct_title')) {
      context.handle(
          _correctTitleMeta,
          correctTitle.isAcceptableOrUnknown(
              data['correct_title']!, _correctTitleMeta));
    }
    if (data.containsKey('correct_artist')) {
      context.handle(
          _correctArtistMeta,
          correctArtist.isAcceptableOrUnknown(
              data['correct_artist']!, _correctArtistMeta));
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
          _thumbnailUrlMeta,
          thumbnailUrl.isAcceptableOrUnknown(
              data['thumbnail_url']!, _thumbnailUrlMeta));
    }
    if (data.containsKey('youtube_id')) {
      context.handle(_youtubeIdMeta,
          youtubeId.isAcceptableOrUnknown(data['youtube_id']!, _youtubeIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {filePath};
  @override
  TrackOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackOverride(
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      correctTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correct_title']),
      correctArtist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correct_artist']),
      thumbnailUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url']),
      youtubeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}youtube_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TrackOverridesTable createAlias(String alias) {
    return $TrackOverridesTable(attachedDatabase, alias);
  }
}

class TrackOverride extends DataClass implements Insertable<TrackOverride> {
  final String filePath;
  final String? correctTitle;
  final String? correctArtist;
  final String? thumbnailUrl;
  final String? youtubeId;
  final DateTime updatedAt;
  const TrackOverride(
      {required this.filePath,
      this.correctTitle,
      this.correctArtist,
      this.thumbnailUrl,
      this.youtubeId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || correctTitle != null) {
      map['correct_title'] = Variable<String>(correctTitle);
    }
    if (!nullToAbsent || correctArtist != null) {
      map['correct_artist'] = Variable<String>(correctArtist);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || youtubeId != null) {
      map['youtube_id'] = Variable<String>(youtubeId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TrackOverridesCompanion toCompanion(bool nullToAbsent) {
    return TrackOverridesCompanion(
      filePath: Value(filePath),
      correctTitle: correctTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(correctTitle),
      correctArtist: correctArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(correctArtist),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      youtubeId: youtubeId == null && nullToAbsent
          ? const Value.absent()
          : Value(youtubeId),
      updatedAt: Value(updatedAt),
    );
  }

  factory TrackOverride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackOverride(
      filePath: serializer.fromJson<String>(json['filePath']),
      correctTitle: serializer.fromJson<String?>(json['correctTitle']),
      correctArtist: serializer.fromJson<String?>(json['correctArtist']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      youtubeId: serializer.fromJson<String?>(json['youtubeId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'filePath': serializer.toJson<String>(filePath),
      'correctTitle': serializer.toJson<String?>(correctTitle),
      'correctArtist': serializer.toJson<String?>(correctArtist),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'youtubeId': serializer.toJson<String?>(youtubeId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TrackOverride copyWith(
          {String? filePath,
          Value<String?> correctTitle = const Value.absent(),
          Value<String?> correctArtist = const Value.absent(),
          Value<String?> thumbnailUrl = const Value.absent(),
          Value<String?> youtubeId = const Value.absent(),
          DateTime? updatedAt}) =>
      TrackOverride(
        filePath: filePath ?? this.filePath,
        correctTitle:
            correctTitle.present ? correctTitle.value : this.correctTitle,
        correctArtist:
            correctArtist.present ? correctArtist.value : this.correctArtist,
        thumbnailUrl:
            thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
        youtubeId: youtubeId.present ? youtubeId.value : this.youtubeId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TrackOverride copyWithCompanion(TrackOverridesCompanion data) {
    return TrackOverride(
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      correctTitle: data.correctTitle.present
          ? data.correctTitle.value
          : this.correctTitle,
      correctArtist: data.correctArtist.present
          ? data.correctArtist.value
          : this.correctArtist,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      youtubeId: data.youtubeId.present ? data.youtubeId.value : this.youtubeId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackOverride(')
          ..write('filePath: $filePath, ')
          ..write('correctTitle: $correctTitle, ')
          ..write('correctArtist: $correctArtist, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('youtubeId: $youtubeId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(filePath, correctTitle, correctArtist,
      thumbnailUrl, youtubeId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackOverride &&
          other.filePath == this.filePath &&
          other.correctTitle == this.correctTitle &&
          other.correctArtist == this.correctArtist &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.youtubeId == this.youtubeId &&
          other.updatedAt == this.updatedAt);
}

class TrackOverridesCompanion extends UpdateCompanion<TrackOverride> {
  final Value<String> filePath;
  final Value<String?> correctTitle;
  final Value<String?> correctArtist;
  final Value<String?> thumbnailUrl;
  final Value<String?> youtubeId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TrackOverridesCompanion({
    this.filePath = const Value.absent(),
    this.correctTitle = const Value.absent(),
    this.correctArtist = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.youtubeId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackOverridesCompanion.insert({
    required String filePath,
    this.correctTitle = const Value.absent(),
    this.correctArtist = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.youtubeId = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : filePath = Value(filePath),
        updatedAt = Value(updatedAt);
  static Insertable<TrackOverride> custom({
    Expression<String>? filePath,
    Expression<String>? correctTitle,
    Expression<String>? correctArtist,
    Expression<String>? thumbnailUrl,
    Expression<String>? youtubeId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (filePath != null) 'file_path': filePath,
      if (correctTitle != null) 'correct_title': correctTitle,
      if (correctArtist != null) 'correct_artist': correctArtist,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (youtubeId != null) 'youtube_id': youtubeId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackOverridesCompanion copyWith(
      {Value<String>? filePath,
      Value<String?>? correctTitle,
      Value<String?>? correctArtist,
      Value<String?>? thumbnailUrl,
      Value<String?>? youtubeId,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TrackOverridesCompanion(
      filePath: filePath ?? this.filePath,
      correctTitle: correctTitle ?? this.correctTitle,
      correctArtist: correctArtist ?? this.correctArtist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      youtubeId: youtubeId ?? this.youtubeId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (correctTitle.present) {
      map['correct_title'] = Variable<String>(correctTitle.value);
    }
    if (correctArtist.present) {
      map['correct_artist'] = Variable<String>(correctArtist.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (youtubeId.present) {
      map['youtube_id'] = Variable<String>(youtubeId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackOverridesCompanion(')
          ..write('filePath: $filePath, ')
          ..write('correctTitle: $correctTitle, ')
          ..write('correctArtist: $correctArtist, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('youtubeId: $youtubeId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $TracksTable tracks = $TracksTable(this);
  late final $YouTubeTracksTable youTubeTracks = $YouTubeTracksTable(this);
  late final $HomeCacheTable homeCache = $HomeCacheTable(this);
  late final $RadioStationsTable radioStations = $RadioStationsTable(this);
  late final $PlaybackLogTable playbackLog = $PlaybackLogTable(this);
  late final $TrackOverridesTable trackOverrides = $TrackOverridesTable(this);
  late final Index idxTracksFolder = Index('idx_tracks_folder',
      'CREATE INDEX idx_tracks_folder ON tracks (folder_path)');
  late final Index idxTracksAlbum = Index(
      'idx_tracks_album', 'CREATE INDEX idx_tracks_album ON tracks (album)');
  late final Index idxTracksArtist = Index(
      'idx_tracks_artist', 'CREATE INDEX idx_tracks_artist ON tracks (artist)');
  late final Index idxTracksFavorite = Index('idx_tracks_favorite',
      'CREATE INDEX idx_tracks_favorite ON tracks (is_favorite, last_played)');
  late final Index idxTracksExcluded = Index('idx_tracks_excluded',
      'CREATE INDEX idx_tracks_excluded ON tracks (is_excluded)');
  late final Index idxYtFavorite = Index('idx_yt_favorite',
      'CREATE INDEX idx_yt_favorite ON you_tube_tracks (is_favorite, liked_at)');
  late final Index idxYtDownloaded = Index('idx_yt_downloaded',
      'CREATE INDEX idx_yt_downloaded ON you_tube_tracks (download_path)');
  late final Index idxYtLastPlayed = Index('idx_yt_lastPlayed',
      'CREATE INDEX idx_yt_lastPlayed ON you_tube_tracks (last_played)');
  late final Index idxYtCachedAt = Index('idx_yt_cachedAt',
      'CREATE INDEX idx_yt_cachedAt ON you_tube_tracks (cached_at)');
  late final Index idxPlaybackVideo = Index('idx_playback_video',
      'CREATE INDEX idx_playback_video ON playback_log (video_id)');
  late final Index idxPlaybackPlayedAt = Index('idx_playback_playedAt',
      'CREATE INDEX idx_playback_playedAt ON playback_log (played_at)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        tracks,
        youTubeTracks,
        homeCache,
        radioStations,
        playbackLog,
        trackOverrides,
        idxTracksFolder,
        idxTracksAlbum,
        idxTracksArtist,
        idxTracksFavorite,
        idxTracksExcluded,
        idxYtFavorite,
        idxYtDownloaded,
        idxYtLastPlayed,
        idxYtCachedAt,
        idxPlaybackVideo,
        idxPlaybackPlayedAt
      ];
}
