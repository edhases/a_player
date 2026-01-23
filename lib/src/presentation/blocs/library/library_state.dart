part of 'library_bloc.dart';

// Needs imports for AppDatabase types if used here directly,
// OR simpler: since it's a part file, it shares imports with library_bloc.dart?
// NO, "part of" files usually share the scope of the main file, but if types are used in "part" they must be visible in main file.
// library_bloc.dart imports app_database.dart, so AlbumWithArtwork etc should be visible here.
// But the linter complained. Let's check why.
// Ah, the linter said "The name ... isn't a type", implying it might not be exported from app_database.dart or I missed the import in library_bloc.dart?
// expected: import '../../../../data/datasources/app_database.dart'; is there in library_bloc.dart.
// EXCEPT: "target of URI doesn't exist" in previous lint error suggests the path in library_bloc.dart is WRONG.
// e:\Github\a_player\lib\src\presentation\blocs\library\library_bloc.dart
// path to app_database: lib/src/data/datasources/app_database.dart
// relative: ../../../../data/datasources/app_database.dart
// src/presentation/blocs/library (4 levels down from src?)
// lib/src/presentation/blocs/library
// ../ -> blocs
// ../../ -> presentation
// ../../../ -> src
// ../../../../ -> lib ? NO.
// lib/src/
//   presentation/
//     blocs/
//       library/
//         library_bloc.dart
//   data/
//     datasources/
//       app_database.dart

// From library_bloc.dart:
// ../ (blocs)
// ../../ (presentation)
// ../../../ (src)
// ../../../../ (lib) - wait.
// If file is in lib/src/presentation/blocs/library/
// 1 .. = blocs
// 2 .. = presentation
// 3 .. = src
// 4 .. = lib? No, 3.. points to 'src'.
// So path to data/datasources/app_database.dart from 'src' is:
// data/datasources/app_database.dart
// So: ../../../data/datasources/app_database.dart

// Copying LibraryViewMode enum here or importing?
// Better to move enum to entity or keep here.
// Let's assume it's moved or redefined here to be self-contained in Bloc state if it's UI state.
enum LibraryViewMode { folders, albums, artists, radio }

enum LibraryStatus { initial, loading, success, failure }

class LibraryState extends Equatable {
  final LibraryStatus status;
  final LibraryViewMode viewMode;
  final List<String> folders;
  final List<AlbumWithArtwork> albums;
  final List<Artist> artists;
  final List<RadioStation> radioStations;
  final List<String> excludedFolders;
  final String? errorMessage;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.viewMode = LibraryViewMode.folders,
    this.folders = const [],
    this.albums = const [],
    this.artists = const [],
    this.radioStations = const [],
    this.excludedFolders = const [],
    this.errorMessage,
  });

  LibraryState copyWith({
    LibraryStatus? status,
    LibraryViewMode? viewMode,
    List<String>? folders,
    List<AlbumWithArtwork>? albums,
    List<Artist>? artists,
    List<RadioStation>? radioStations,
    List<String>? excludedFolders,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      folders: folders ?? this.folders,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      radioStations: radioStations ?? this.radioStations,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        viewMode,
        folders,
        albums,
        artists,
        radioStations,
        excludedFolders,
        errorMessage,
      ];
}
