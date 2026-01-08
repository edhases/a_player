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
  @override
  List<GeneratedColumn> get $columns => [
        videoId,
        title,
        artist,
        thumbnailUrl,
        duration,
        downloadPath,
        lastPlayed,
        cachedAt
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
      lastPlayed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_played']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
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
  final DateTime? lastPlayed;
  final DateTime cachedAt;
  const YouTubeTrack(
      {required this.videoId,
      required this.title,
      required this.artist,
      required this.thumbnailUrl,
      required this.duration,
      this.downloadPath,
      this.lastPlayed,
      required this.cachedAt});
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
    if (!nullToAbsent || lastPlayed != null) {
      map['last_played'] = Variable<DateTime>(lastPlayed);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
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
      lastPlayed: lastPlayed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayed),
      cachedAt: Value(cachedAt),
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
      lastPlayed: serializer.fromJson<DateTime?>(json['lastPlayed']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
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
      'lastPlayed': serializer.toJson<DateTime?>(lastPlayed),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  YouTubeTrack copyWith(
          {String? videoId,
          String? title,
          String? artist,
          String? thumbnailUrl,
          int? duration,
          Value<String?> downloadPath = const Value.absent(),
          Value<DateTime?> lastPlayed = const Value.absent(),
          DateTime? cachedAt}) =>
      YouTubeTrack(
        videoId: videoId ?? this.videoId,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        duration: duration ?? this.duration,
        downloadPath:
            downloadPath.present ? downloadPath.value : this.downloadPath,
        lastPlayed: lastPlayed.present ? lastPlayed.value : this.lastPlayed,
        cachedAt: cachedAt ?? this.cachedAt,
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
      lastPlayed:
          data.lastPlayed.present ? data.lastPlayed.value : this.lastPlayed,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
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
          ..write('lastPlayed: $lastPlayed, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, title, artist, thumbnailUrl,
      duration, downloadPath, lastPlayed, cachedAt);
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
          other.lastPlayed == this.lastPlayed &&
          other.cachedAt == this.cachedAt);
}

class YouTubeTracksCompanion extends UpdateCompanion<YouTubeTrack> {
  final Value<String> videoId;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> thumbnailUrl;
  final Value<int> duration;
  final Value<String?> downloadPath;
  final Value<DateTime?> lastPlayed;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const YouTubeTracksCompanion({
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.downloadPath = const Value.absent(),
    this.lastPlayed = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  YouTubeTracksCompanion.insert({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int duration,
    this.downloadPath = const Value.absent(),
    this.lastPlayed = const Value.absent(),
    required DateTime cachedAt,
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
    Expression<DateTime>? lastPlayed,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (duration != null) 'duration': duration,
      if (downloadPath != null) 'download_path': downloadPath,
      if (lastPlayed != null) 'last_played': lastPlayed,
      if (cachedAt != null) 'cached_at': cachedAt,
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
      Value<DateTime?>? lastPlayed,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return YouTubeTracksCompanion(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      downloadPath: downloadPath ?? this.downloadPath,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      cachedAt: cachedAt ?? this.cachedAt,
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
    if (lastPlayed.present) {
      map['last_played'] = Variable<DateTime>(lastPlayed.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
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
          ..write('lastPlayed: $lastPlayed, ')
          ..write('cachedAt: $cachedAt, ')
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
  late final GeneratedColumn<List<Map<String, dynamic>>> data =
      GeneratedColumn<List<Map<String, dynamic>>>(
              'data', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<Map<String, dynamic>>>(
              $HomeCacheTable.$converterdata);
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
      data: $HomeCacheTable.$converterdata.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $HomeCacheTable createAlias(String alias) {
    return $HomeCacheTable(attachedDatabase, alias);
  }

  static const TypeConverter<List<Map<String, dynamic>>, String> $converterdata =
      HomeCacheDataConverter();
}

class HomeCacheEntry extends DataClass implements Insertable<HomeCacheEntry> {
  final int id;
  final List<Map<String, dynamic>> data;
  final DateTime timestamp;
  const HomeCacheEntry(
      {required this.id, required this.data, required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      final converter = $HomeCacheTable.$converterdata;
      map['data'] = Variable<String>(converter.toSql(data));
    }
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
      data: serializer.fromJson<List<Map<String, dynamic>>>(json['data']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'data': serializer.toJson<List<Map<String, dynamic>>>(data),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  HomeCacheEntry copyWith(
          {int? id,
          List<Map<String, dynamic>>? data,
          DateTime? timestamp}) =>
      HomeCacheEntry(
        id: id ?? this.id,
        data: data ?? this.data,
        timestamp: timestamp ?? this.timestamp,
      );
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
  int get hashCode => Object.hash(id, $driftBlobEquality.hash(data), timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeCacheEntry &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.timestamp == this.timestamp);
}

class HomeCacheCompanion extends UpdateCompanion<HomeCacheEntry> {
  final Value<int> id;
  final Value<List<Map<String, dynamic>>> data;
  final Value<DateTime> timestamp;
  const HomeCacheCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  HomeCacheCompanion.insert({
    this.id = const Value.absent(),
    required List<Map<String, dynamic>> data,
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
      {Value<int>? id,
      Value<List<Map<String, dynamic>>>? data,
      Value<DateTime>? timestamp}) {
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
      final converter = $HomeCacheTable.$converterdata;
      map['data'] = Variable<String>(converter.toSql(data.value));
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $YouTubeTracksTable youTubeTracks = $YouTubeTracksTable(this);
  late final $HomeCacheTable homeCache = $HomeCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [tracks, youTubeTracks, homeCache];
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$YouTubeTracksTableTableManager get youTubeTracks =>
      $$YouTubeTracksTableTableManager(_db, _db.youTubeTracks);
  $$HomeCacheTableTableManager get homeCache =>
      $$HomeCacheTableTableManager(_db, _db.homeCache);
}
